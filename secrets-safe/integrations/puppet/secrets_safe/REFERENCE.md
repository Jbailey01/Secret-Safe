# Functions

## Common parameters
Each of the following functions have some common parameters:


### `host`

Data type: String

Hostname or IP address of Secrets Safe instance

### `app_name`

Data type: String

Name of Secrets Safe application used to perform this action

### `api_key`

Data type: String

Api key of the Secrets Safe application specified in the app_name parameter

### `secret_uri`

Data type: String

URI of the secret being operated on

## dss_get_secret(host, secret_uri, app_name, api_key)
Returns the value of a Secrets Safe secret found at secret_uri



## dss_create_secret_with_value(host, secret_uri, app_name, api_key, secret_value)
Creates a secret at secret_uri using the value of _secret_value
#### Parameters

### `secret_value`

Data type: String

String value of the secret to be stored

## dss_create_secret_with_generator(host, secret_uri, app_name, api_key, generator_name)
Creates a secret at secret_uri using the Secrets Safe generator specified in generator_name
#### Parameters

### `generator_name`

Data type: String

Name of the Secrets Safe generator used to generate the value for this secret

## dss_create_secret_with_file(host, secret_uri, app_name, api_key, file_name)
Creates a secret at secret_uri using the file at file_name as the value
#### Parameters

### `file_name`

Data type: String

Path to the file which will be stored as a secret