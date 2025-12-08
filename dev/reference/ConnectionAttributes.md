# Supported Connection Attributes

These (pre) connection attributes are supported and can be passed as
part of the `dbConnect` call in the named list `attributes` parameter:

## Details

- `azure_token`: This should be a string scalar; in particular Azure
  Active Directory authentication token. Only for use with Microsoft SQL
  Server and with limited support away from the OEM Microsoft driver.

- `sf_private_key`: This parameter is specific to establishing a
  connection to `snowflake` and is understood by both OEM, as well as
  `Posit` pro drivers. Argument should be a string (scalar); in
  particular a PEM-encoded private key. Note, if using private key
  authentication, the `authenticator` connection string attribute must
  be set to `SNOWFLAKE_JWT`. Using this *connection* attribute is an
  alternative to using the `PRIV_KEY_FILE` connection string attribute.

- `sf_private_key_password`: If key passed using `sf_private_key` is
  encrypted, you can use this attribute to communicate the password.

## Examples
