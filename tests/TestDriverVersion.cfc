component extends="org.lucee.cfml.test.LuceeTestCase" labels="redshiftx" {

	// keep in sync with pom.xml mvnVersion (major.minor.patch.build prefix)
	variables.mavenDriverVersionPrefix = "2.2.8";

	function isNotSupported() {
		// there is no local Amazon Redshift; only run when a "redshift" datasource is configured
		return isEmpty( server.getDatasource( "redshift" ) );
	}

	private boolean function luceeSupportsMavenJdbc() {
		try {
			return server.doesJDBCSupportMaven();
		} catch ( any e ) {
			return false;
		}
	}

	private struct function getDatasourceResolution( required struct ds ) {
		var usesMaven = structKeyExists( arguments.ds, "maven" ) && len( arguments.ds.maven );

		return {
			mode: usesMaven ? "maven" : "bundle",
			maven: usesMaven ? arguments.ds.maven : "",
			bundleName: structKeyExists( arguments.ds, "bundleName" ) ? arguments.ds.bundleName : "",
			bundleVersion: structKeyExists( arguments.ds, "bundleVersion" ) ? arguments.ds.bundleVersion : "",
			luceeSupportsMavenJdbc: luceeSupportsMavenJdbc()
		};
	}

	function run( testResults, testBox ) {
		describe( title="Amazon Redshift JDBC extension driver version", body=function() {
			it(
				title="reports the Amazon Redshift JDBC driver version in use",
				skip=isNotSupported(),
				body=function( currentSpec ) {
					var ds = server.getDatasource( "redshift" );
					var resolution = getDatasourceResolution( ds );

					dbinfo datasource=ds name="local.dbVersion" type="version";

					var info = {
						luceeVersion: server.lucee.version,
						datasourceClass: ds.class,
						datasourceResolution: resolution,
						driverName: dbVersion.driver_name,
						driverVersion: dbVersion.driver_version,
						databaseProduct: dbVersion.database_productname,
						databaseVersion: dbVersion.database_version,
						jdbcVersion: dbVersion.jdbc_major_version & "." & dbVersion.jdbc_minor_version
					};

					systemOutput( "Amazon Redshift JDBC driver info: " & serializeJSON( info ), true );

					expect( dbVersion.recordCount ).toBe( 1 );
					expect( dbVersion.driver_name ).toInclude( "Redshift" );

					if ( resolution.mode eq "maven" ) {
						expect( dbVersion.driver_version ).toInclude( variables.mavenDriverVersionPrefix );
					} else {
						systemOutput( "Amazon Redshift JDBC driver loaded via OSGi bundle (#resolution.bundleName# #resolution.bundleVersion#); Maven version assertion skipped", true );
					}
				}
			);
		} );
	}

}
