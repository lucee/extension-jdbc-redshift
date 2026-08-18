component extends="org.lucee.cfml.test.LuceeTestCase" labels="redshiftx" {
    /*

    the lucee test suite runs without a live Amazon Redshift cluster, so the redshift stuff can't be unit tested

    the test suite fails if no matching tests are found, so this is a no-op test so CI passes

    */
    function testNothing() {
        expect (true ).toBeTrue();
    }
}
