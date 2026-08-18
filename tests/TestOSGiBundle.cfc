component extends="org.lucee.cfml.test.LuceeTestCase" labels="redshiftx" {

	// keep in sync with pom.xml project.version (== the embedded driver bundle version)
	variables.bundleName    = "org.lucee.redshift-jdbc42";
	variables.bundleVersion = "2.2.8.0-SNAPSHOT";
	variables.driverClass   = "com.amazon.redshift.Driver";

	/**
	* Builds a Redshift datasource pointing at an unreachable host and tries to use it.
	* Using the datasource forces Lucee to load the driver out of the OSGi bundle, so the
	* resulting exception tells us exactly what we want to know - with NO live Redshift and
	* NO skipping:
	*   - a CONNECTION error   => the OSGi bundle loaded and the driver works        (PASS)
	*   - a BUNDLE-LOAD error   => the extension's OSGi bundle is missing/unresolved  (FAIL)
	*/
	private struct function useUnreachableDatasource() {
		var res = { connected: false, error: "" };
		var ds = {
			  class: variables.driverClass
			, bundleName: variables.bundleName
			, bundleVersion: variables.bundleVersion
			// nothing listens on 127.0.0.1:5439 in CI -> a fast "connection refused"
			, connectionString: "jdbc:redshift://127.0.0.1:5439/dev?loginTimeout=5"
			, username: "lucee"
			, password: "lucee"
		};
		try {
			queryExecute( "SELECT 1", [], { datasource: ds } );
			res.connected = true; // not expected against a dead host, but means the bundle loaded
		} catch ( any e ) {
			res.error = e.message & " | " & ( e.detail ?: "" );
		}
		return res;
	}

	// The OSGi bundle failing to load/resolve is the failure we must catch (e.g. a missing
	// Import-Package like org.bouncycastle.jsse.provider, or the bundle not being deployed).
	private boolean function isBundleLoadFailure( required string err ) {
		var m = arguments.err;
		return findNoCase( "OSGi Bundle", m )
			|| findNoCase( "not available", m )
			|| findNoCase( "Unable to resolve", m )
			|| findNoCase( "missing requirement", m )
			|| findNoCase( "Unresolved requirement", m )
			|| ( findNoCase( "unable to load", m ) && findNoCase( "bundle", m ) );
	}

	// The failure we EXPECT: the driver loaded and could not reach the unreachable host.
	private boolean function isConnectionFailure( required string err ) {
		var m = arguments.err;
		return findNoCase( "refused", m )
			|| findNoCase( "Connection to", m )
			|| findNoCase( "connection attempt failed", m )
			|| findNoCase( "could not connect", m )
			|| findNoCase( "timeout", m ) || findNoCase( "timed out", m )
			|| findNoCase( "UnknownHost", m ) || findNoCase( "route to host", m );
	}

	function run( testResults, testBox ) {
		variables.outcome = useUnreachableDatasource();

		describe( title="Amazon Redshift JDBC driver via a datasource", body=function() {

			it(
				title="loads the OSGi bundle and fails to connect to an unreachable host (never with a bundle-load error)",
				body=function( currentSpec ) {
					var o = variables.outcome;

					if ( o.connected ) {
						// unexpected against a dead host, but it proves the bundle loaded
						systemOutput( "Amazon Redshift datasource unexpectedly connected (OSGi bundle loaded ok)", true );
						expect( true ).toBeTrue();
						return;
					}

					systemOutput( "Amazon Redshift datasource error: " & o.error, true );

					// the driver's OSGi bundle MUST load - a bundle-load error is a hard failure
					expect( isBundleLoadFailure( o.error ) ).toBeFalse(
						"driver OSGi bundle failed to load (expected a connection error instead): " & o.error );

					// and the error we DO expect is a connection failure to the unreachable host
					expect( isConnectionFailure( o.error ) ).toBeTrue(
						"expected a connection failure to the unreachable host, got: " & o.error );
				}
			);
		} );
	}

}
