/**
 * Verifies the Amazon Redshift driver is usable through a datasource, without a live cluster.
 * Defines a Redshift datasource pointing at an unreachable host and runs a query. Using the
 * datasource forces Lucee to load the driver, so the exception tells us exactly what we need -
 * with NO live Redshift and NO skipping:
 *   - a CONNECTION error   => the driver loaded and works           (what we EXPECT)
 *   - a LOAD error         => the driver could not be loaded        (what we do NOT expect)
 *
 * The extension ships the driver twice, so both load paths are checked:
 *   - OSGi  : bundleName/bundleVersion of the wrapped bundle org.lucee.redshift-jdbc42
 *   - Maven : the original com.amazon.redshift:redshift-jdbc42 (Lucee 7.1.0.187+ only)
 */
component extends="org.lucee.cfml.test.LuceeTestCase" labels="redshiftx" {

	variables.driverClass = "com.amazon.redshift.Driver";
	// OSGi wrapped bundle - version tracks org.lucee:redshift, NOT the extension version
	variables.bundleName    = "org.lucee.redshift-jdbc42";
	variables.bundleVersion = "2.2.8.0";
	// original AWS driver on Maven Central
	variables.mavenCoord    = "com.amazon.redshift:redshift-jdbc42:2.2.8";

	private boolean function mavenNotSupported() {
		return !server.checkVersionGTE( server.lucee.version, 7, 1, 0, 187 );
	}

	function run( testResults, testBox ) {

		describe( "Amazon Redshift JDBC driver via a datasource", function() {

			it( title="OSGi path: loads the wrapped bundle and reaches the connect stage", body=function() {
				assertLoadsThenFailsToConnect( getOsgiDatasource(), "OSGi" );
			});

			it( title="Maven path: loads the AWS driver from maven and reaches the connect stage", skip=mavenNotSupported(), body=function() {
				assertLoadsThenFailsToConnect( getMavenDatasource(), "Maven" );
			});

		});
	}

	// core assertion: using the datasource must fail with a CONNECTION error, never a driver-LOAD error
	private void function assertLoadsThenFailsToConnect( required struct ds, required string path ) {
		var err = queryUnreachable( arguments.ds );

		if ( !len( err ) ) {
			systemOutput( "OK: Amazon Redshift driver [#arguments.path# path] loaded; datasource unexpectedly connected", true );
			expect( true ).toBeTrue();
			return;
		}

		var loadFailed = isDriverLoadFailure( err );
		var connFailed = isConnectionFailure( err );

		// make it obvious in the log that this exception is the desired outcome, not a test failure
		if ( connFailed && !loadFailed ) {
			systemOutput( "OK (expected): Amazon Redshift driver [#arguments.path# path] loaded and works - the connection to the unreachable test host was refused as expected. Expected exception: " & err, true );
		} else {
			systemOutput( "UNEXPECTED: Amazon Redshift driver [#arguments.path# path] did NOT load (expected a connection error instead). Exception: " & err, true );
		}

		expect( loadFailed ).toBeFalse(
			"[#arguments.path# path] driver failed to LOAD; expected a connection error instead: " & err );
		expect( connFailed ).toBeTrue(
			"[#arguments.path# path] expected a connection failure to the unreachable host, got: " & err );
	}

	private string function queryUnreachable( required struct ds ) {
		try {
			queryExecute( "SELECT 1", {}, { datasource: arguments.ds } );
			return "";
		} catch ( any e ) {
			return e.message & " | " & ( e.detail ?: "" );
		}
	}

	private struct function getOsgiDatasource() {
		return {
			  class: variables.driverClass
			, bundleName: variables.bundleName
			, bundleVersion: variables.bundleVersion
			, connectionString: "jdbc:redshift://127.0.0.1:5439/dev?loginTimeout=5"
			, username: "lucee", password: "lucee", validate: false
		};
	}

	private struct function getMavenDatasource() {
		return {
			  class: variables.driverClass
			, maven: variables.mavenCoord
			, connectionString: "jdbc:redshift://127.0.0.1:5439/dev?loginTimeout=5"
			, username: "lucee", password: "lucee", validate: false
		};
	}

	// failing to LOAD the driver (missing OSGi bundle / unresolvable maven artifact) - NOT a connection problem
	private boolean function isDriverLoadFailure( required string err ) {
		var m = arguments.err;
		return findNoCase( "OSGi Bundle", m )
			|| findNoCase( "not available", m )
			|| findNoCase( "Unable to resolve", m )
			|| findNoCase( "missing requirement", m )
			|| findNoCase( "Unresolved requirement", m )
			|| findNoCase( "Failed to load class", m )
			|| ( findNoCase( "unable to load", m ) && ( findNoCase( "bundle", m ) || findNoCase( "class", m ) ) );
	}

	// the failure we EXPECT: the driver loaded and could not reach the unreachable host
	private boolean function isConnectionFailure( required string err ) {
		var m = arguments.err;
		return findNoCase( "refused", m )
			|| findNoCase( "Connection to", m )
			|| findNoCase( "connection attempt failed", m )
			|| findNoCase( "could not connect", m )
			|| findNoCase( "timeout", m ) || findNoCase( "timed out", m )
			|| findNoCase( "UnknownHost", m ) || findNoCase( "route to host", m );
	}

}
