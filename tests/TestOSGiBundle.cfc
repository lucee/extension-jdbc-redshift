component extends="org.lucee.cfml.test.LuceeTestCase" labels="redshiftx" {

	// keep in sync with the embedded bundle (org.lucee.redshift-jdbc42-<version>.jar)
	variables.bundleName    = "org.lucee.redshift-jdbc42";
	variables.bundleVersion = "2.2.8";
	variables.driverClass   = "com.amazon.redshift.Driver";

	/**
	* Loads the driver class from the embedded OSGi bundle. This is the exact path
	* (JavaProxy -> loadBundle -> OSGi resolve) that fails when a required package is
	* missing from the bundle's Import-Package, so it verifies the wrapped bundle
	* actually resolves - no live Amazon Redshift cluster required.
	*/
	private struct function loadDriver() {
		var res = { ok: false, error: "" };
		try {
			res.driver = createObject( "java", variables.driverClass, variables.bundleName, variables.bundleVersion );
			res.ok = true;
		} catch ( any e ) {
			res.error = e.message & " | " & ( e.detail ?: "" );
		}
		return res;
	}

	/**
	* A bundle that is simply not deployed in this environment is skipped, but a real
	* OSGi *resolution* failure (an unresolved package requirement) must fail the test.
	*/
	private boolean function isEnvSkip( required struct loaded ) {
		if ( arguments.loaded.ok ) return false;
		var err = arguments.loaded.error;
		if ( findNoCase( "missing requirement", err ) || findNoCase( "Unresolved requirement", err ) ) return false;
		return findNoCase( "load", err ) && findNoCase( "bundle", err );
	}

	function run( testResults, testBox ) {
		variables.loaded = loadDriver();
		var envSkip = isEnvSkip( variables.loaded );

		if ( envSkip ) {
			systemOutput( "Amazon Redshift bundle [#variables.bundleName# #variables.bundleVersion#] not deployed in this environment; OSGi bundle test skipped (" & variables.loaded.error & ")", true );
		}

		describe( title="Amazon Redshift JDBC driver OSGi bundle", body=function() {

			it(
				title="resolves bundle #variables.bundleName# #variables.bundleVersion# and loads #variables.driverClass#",
				skip=envSkip,
				body=function( currentSpec ) {
					expect( variables.loaded.ok ).toBeTrue( "driver bundle failed to load/resolve: " & variables.loaded.error );

					var driver = variables.loaded.driver;

					// java.sql.Driver contract - proves the loaded class is the real driver
					expect( driver.acceptsURL( "jdbc:redshift://localhost:5439/dev" ) ).toBeTrue();
					expect( driver.acceptsURL( "jdbc:mysql://localhost:3306/dev" ) ).toBeFalse();

					var bundle = bundleInfo( driver );
					systemOutput( "Amazon Redshift JDBC driver bundle info: " & serializeJSON( {
						bundleName: bundle.name,
						bundleVersion: bundle.version,
						driverVersion: driver.getMajorVersion() & "." & driver.getMinorVersion()
					} ), true );

					expect( bundle.name ).toBe( variables.bundleName );
				}
			);
		} );
	}

}
