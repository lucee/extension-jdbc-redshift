# Lucee Amazon Redshift JDBC Extension

[![Java CI](https://github.com/lucee/extension-jdbc-redshift/actions/workflows/main.yml/badge.svg)](https://github.com/lucee/extension-jdbc-redshift/actions/workflows/main.yml)

JDBC Type 4 driver extension for [Amazon Redshift](https://docs.aws.amazon.com/redshift/latest/mgmt/jdbc20-download-driver.html).

## OSGi-based extension

The official Amazon Redshift driver (`com.amazon.redshift:redshift-jdbc42`) ships
without OSGi headers, so it cannot be loaded as an OSGi bundle directly. This
extension therefore embeds an **OSGi-wrapped** build of the driver,
`org.lucee:redshift-jdbc42` (produced by the `Tools/osgi` `mavenjar2osgi`
generator), and registers the driver by its bundle name/version:

```
jdbc: "[{'label':'Amazon Redshift JDBC Driver','id':'redshift','connectionString':'jdbc:redshift://{host}:{port}/{database}','class':'com.amazon.redshift.Driver','bundleName':'org.lucee.redshift-jdbc42','bundleVersion':'2.2.8'}]"
```

The wrapped driver jar is embedded in the `.lex` under `jars/`, so the extension is
self-contained and works on any Lucee 5.0.0.019+ (OSGi bundle loading). A Maven-based
variant (registering the driver by Maven coordinate on Lucee 7.1.0.187+) can be added
later as a second step.

## Build

The extension depends on the OSGi-wrapped driver bundle `org.lucee:redshift-jdbc42`.
Once that bundle is published to Maven Central, `mvn clean install` resolves it
automatically. Until then, install the locally built bundle into your local
repository first:

```bash
mvn install:install-file \
  -Dfile=/path/to/org.lucee.redshift-jdbc42-2.2.8.jar \
  -DgroupId=org.lucee -DartifactId=redshift-jdbc42 -Dversion=2.2.8 -Dpackaging=jar
mvn clean install
```

The build produces `target/redshift-jdbc-extension-<version>.lex`.

## Connection string

```
jdbc:redshift://{host}:{port}/{database}
```

Default port is `5439`. Standard user / password authentication works out of the box.
IAM / SSO authentication uses driver features whose supporting libraries (AWS SDK v2,
Apache HttpClient, Jackson, BouncyCastle, …) are declared as optional/dynamic imports
on the wrapped bundle.

Issues: https://luceeserver.atlassian.net/issues/?jql=labels%20%3D%20redshift
