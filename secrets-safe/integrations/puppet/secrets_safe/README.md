## Table of Contents

1. [Description](#description)
1. [Usage - Example usage](#usage)

## Description

This module consists of a number of plugins that allow creation and retrival of secrets in DevOps Secrets Safe.

### Setup Requirements

In order to use the functions included in this module you will need a running instance of Secrets Safe and an application with permissions to perform read and/or write permissions on the resources you interact with.

## Usage


Ensure user bob exists with a password retrieved from Secrets Safe:

    $user_password = dss_get_secret('https://my-secrets-safe.com', 'user/passwords:bob', "my_application", "my_api_key")
    user { 'bob':
      ensure   => present,
      password => Sensitive($user_password)
    }
Use a Secrets Safe generator to generate a password then provision a Postgres database using it:

    class { 'postgresql::server':
    }

    dss_create_secret_with_generator('https://my-secrets-safe.com', 'passwords/db/pg_user', "my_application", "my_api_key", "postgres-password-generator")
    $pg_pass = dss_get_secret('https://my-secrets-safe.com', 'passwords/db/pg_user', "my_application", "my_api_key")
    postgresql::server::db { 'new_postgres':
      user     => 'pg_user',
      password => postgresql::postgresql_password('pg_user', $pg_pass),
    }
Save a certificate that is on the file system as a secret in Secrets Safe:

    dss_create_secret_with_file('https://my-secrets-safe.com', 'certs:mycert', "my_application", "my_api_key", "//etc/ssl/certs/ca.crt")
