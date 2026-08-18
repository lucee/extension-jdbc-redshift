/**
 * Verifies the Amazon Redshift driver is usable through a datasource, without a live cluster.
 * Defines a Redshift datasource pointing at an unreachable host and runs a query. Using the
 * datasource forces Lucee to load the driver out of its OSGi bundle, so the exception tells us
 * exactly what we need - with NO live Redshift and NO skipping:
 *   - a CONNECTION error   => the OSGi bundle loaded and the driver works   (what we EXPECT)
 *   - a BUNDLE-LOAD error  => the extension's OSGi bundle is missing/broken (what we do NOT expect)
 */
component extends="org.lucee.cfml.test.LuceeTestCase" labels="redshiftx" {

	// keep in sync with pom.xml project.version (== the embedded driver bundle version)
	variables.bundleName    = "org.lucee.redshift-jdbc42";
	variables.bundleVersion = "2.2.8.0";
	variables.driverClass   = "com.amazon.redshift.Driver";

	function run( testResults, testBox ) {

		describe( "Amazon Redshift JDBC driver via a datasource", function() {

			it( title="loads the OSGi bundle and reaches the connect stage (fails to connect, not to load the driver)", body=function() {
				var err = queryUnreachableRedshift();

				if ( !len( err ) ) {
					// not expected against a dead host, but it proves the bundle loaded
					systemOutput( "Amazon Redshift datasource unexpectedly connected (OSGi bundle loaded ok)", true );
					expect( true ).toBeTrue();
					return;
				}

				systemOutput( "Amazon Redshift datasource error: " & err, true );

				// the driver's OSGi bundle MUST load - failing to LOAD the driver is a hard failure
				expect( isBundleLoadFailure( err ) ).toBeFalse(
					"driver failed to LOAD (OSGi bundle problem); expected a connection error instead: " & err );

				// what we DO expect: the driver loaded and simply could not reach the unreachable host
				expect( isConnectionFailure( err ) ).toBeTrue(
					"expected a connection failure to the unreachable host, got: " & err );
			});

		});
	}

	// runs a query against a Redshift datasource on an unreachable host; returns the exception text ("" if it somehow connected)
	private string function queryUnreachableRedshift() {
		var ds = getRedshiftDatasource();
		try {
			queryExecute( "SELECT 1", {}, { datasource: ds } );
			return "";
		} catch ( any e ) {
			return e.message & " | " & ( e.detail ?: "" );
		}
	}

	private struct function getRedshiftDatasource() {
		return {
			  class: variables.driverClass
			, bundleName: variables.bundleName
			, bundleVersion: variables.bundleVersion
			// nothing listens on 127.0.0.1:5439 in CI -> a fast, deterministic "connection refused"
			, connectionString: "jdbc:redshift://127.0.0.1:5439/dev?loginTimeout=5"
			, username: "lucee"
			, password: "lucee"
			, validate: false
		};
	}

	// the OSGi bundle failing to load/resolve is the failure we must catch (missing Import-Package,
	// bundle not deployed, etc.) - NOT a connection problem
	private boolean function isBundleLoadFailure( required string err ) {
		var m = arguments.err;
		return findNoCase( "OSGi Bundle", m )
			|| findNoCase( "not available", m )
			|| findNoCase( "Unable to resolve", m )
			|| findNoCase( "missing requirement", m )
			|| findNoCase( "Unresolved requirement", m )
			|| ( findNoCase( "unable to load", m ) && findNoCase( "bundle", m ) );
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
