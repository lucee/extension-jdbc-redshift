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

The OSGi-wrapped driver jar (`org.lucee.redshift-jdbc42-<version>.jar`) is committed
in the repo root; the build reads it, embeds it in the `.lex` under `jars/`, and the
extension works on any Lucee 5.0.0.019+ (OSGi bundle loading). Because the jar is
committed, the build is fully self-contained and needs no Maven Central artifact.
A Maven-based variant (registering the driver by Maven coordinate on Lucee 7.1.0.187+)
can be added later as a second step.

## Build

```bash
mvn clean install
```

The build produces `target/redshift-jdbc-extension-<version>.lex`.

To update the driver, regenerate the wrapped bundle with the `Tools/osgi`
`mavenjar2osgi` generator, replace the committed `org.lucee.redshift-jdbc42-*.jar`
in the repo root, and bump the version in `pom.xml`.

## Connection string

```
jdbc:redshift://{host}:{port}/{database}
```

Default port is `5439`. Standard user / password authentication works out of the box.
IAM / SSO authentication uses driver features whose supporting libraries (AWS SDK v2,
Apache HttpClient, Jackson, BouncyCastle, …) are declared as optional/dynamic imports
on the wrapped bundle.

Issues: https://luceeserver.atlassian.net/issues/?jql=labels%20%3D%20redshift
