component extends="types.Driver" output="no" implements="types.IDatasource" {

	fields=array(
		field("SSL","ssl","true,false",false,
			"Should the driver use SSL to encrypt the connection to the Amazon Redshift cluster? Amazon Redshift requires SSL by default."
			,"radio"),
		field("SSL Mode","sslmode","verify-ca,verify-full,require,prefer,allow,disable",false,
			"Determines how the driver verifies the server certificate when SSL is enabled. ""verify-full"" is the most secure; ""verify-ca"" checks the certificate authority; the remaining modes progressively relax verification."
			,"select"),
		field("Login Timeout","loginTimeout","",false,
			"The number of seconds the driver waits when attempting to establish a connection before timing out. Leave empty for the driver default (no timeout)."),
		field("Socket Timeout","socketTimeout","",false,
			"The number of seconds the driver waits for a socket read operation before timing out. Leave empty for the driver default (no timeout)."),
		field("TCP Keep Alive","tcpKeepAlive","true,false",false,
			"Should the driver enable TCP keep-alive on the underlying socket to detect dropped connections?"
			,"radio"),
		field("DB User","DbUser","",false,
			"When authenticating with IAM credentials, the database user name the driver connects as. Leave empty for standard user/password authentication."),
		field("Login To RP","loginToRp","",false,
			"When using IAM authentication, the name of the redirect endpoint used during single sign-on. Leave empty for standard authentication.")
	);

	this.type.port=this.TYPE_FREE;

	this.value.host="localhost";
	this.value.port=5439;
	this.className="{class-name}";
	this.bundleName="{bundle-name}";
	this.maven="{maven}";
	this.dsn="{connstr}";

	/**
	* returns display name of the driver
	*/
	public string function getName() {
		return "{label}";
	}

	/**
	* returns the id of the driver
	*/
	public string function getId() {
		return "{id}";
	}

	/**
	* returns the description of the driver
	*/
	public string function getDescription() {
		return "{description}";
	}

	/**
	* returns array of fields
	*/
	public array function getFields() {
		return fields;
	}

	public string function getUsername() {
		return data.username;
	}

	public string function getPassword() {
		return data.password;
	}
}
