<!-- omit in toc -->
Secrets Safe Ansible Users Guide
============================

- [Installing the Secrets Safe package](#installing-the-secrets-safe-package)
- [Configuring Ansible to discover the Secrets Safe Lookup Plugin and Modules](#configuring-ansible-to-discover-the-secrets-safe-lookup-plugin-and-modules)
- [Executing the plugin with environment variables](#executing-the-plugin-with-environment-variables)
- [Common Options](#common-options)
- [secretssafelookup Lookup Plugin](#secretssafelookup-lookup-plugin)
  - [Description](#description)
  - [Options](#options)
  - [Examples](#examples)
    - [Retrieve and display multiple secrets from DSS using string arguments.](#retrieve-and-display-multiple-secrets-from-dss-using-string-arguments)
    - [Retrieve and display multiple secrets from DSS, reading the configuration from the environment.](#retrieve-and-display-multiple-secrets-from-dss-reading-the-configuration-from-the-environment)
    - [Retrieve and display a single secret from DSS, reading the configuration from defined variables as keyword arguments.](#retrieve-and-display-a-single-secret-from-dss-reading-the-configuration-from-defined-variables-as-keyword-arguments)
  - [Retrieve and display multiple secrets from DSS, reading the configuration from defined variables as keyword arguments.](#retrieve-and-display-multiple-secrets-from-dss-reading-the-configuration-from-defined-variables-as-keyword-arguments)
- [create_secret Module](#create_secret-module)
  - [Description](#description-1)
  - [Options](#options-1)
  - [Examples](#examples-1)
    - [Create Secret From File](#create-secret-from-file)
    - [Create Secret From Fact:](#create-secret-from-fact)
    - [Create Secret From Generator](#create-secret-from-generator)
- [secretssafe_dynamic_account_create Module](#secretssafe_dynamic_account_create-module)
  - [Description](#description-2)
  - [Options](#options-2)
  - [Examples](#examples-2)
    - [Create Dynamic Account and Copy Output to File](#create-dynamic-account-and-copy-output-to-file)


**Prerequisite: You will require access to the secretssafe python package, installable from a BeyondTrust provided .whl file. In order to run any Secrets Safe plugin or module a python interpreter of version 3.6 or greater must be used.**

## Installing the Secrets Safe package

The Secrets Safe lookup plugin and modules import the `secretssafe`  package and create an instance of the client which communicates with the Secrets Safe API. Install the `secretssafe` package to your python environment using pip:

```
$ pip install secretssafe-<version_details>.whl
```


## Configuring Ansible to discover the Secrets Safe Lookup Plugin and Modules


<!-- omit in toc -->
#### To load any of the Secrets Safe Ansible integrations automatically:

For the Secrets Safe lookup plugin do any of the following:

- Store it in `~/.ansible/plugins/lookup` 
- Store it in `/usr/share/ansible/plugins/lookup`
- Place the path to the plugin in your `ansible.cfg` file

For any of the Secrets Safe Ansible modules do any of the following:
- Store it in `~/.ansible/plugins/modules`
- Store it in `/usr/share/ansible/plugins/modules`
- Place the path to the plugin in your `ansible.cfg` file

<!-- omit in toc -->
#### To use the Ansible components in certain playbooks: 

For the Secrets Safe lookup plugin:
- Store it in subdirectory named `lookup_plugins` in the directory that contains the playbook

For the Secrets Safe modules:
-  Store it in subdirectory named `library` in the directory that contains the playbook

To use the environment to configure the plugin location, export the following:
```
# for the Secrets Safe lookup plugin
$ export ANSIBLE_LOOKUP_PLUGINS=<path/to/secretssafe/lookup/plugin/directory/>
# for the Secrets Safe modules
$ export ANSIBLE_LIBRARY=<path/to/secretssafe/module/directory/>
```

Once properly configured, validate the discovery of the plugin:

```
$ ansible-doc -t lookup secretssafelookup
$ ansible-doc -t module secretssafe_dynamic_account_create
$ ansible-doc -t module secretssafe_create
```

## Executing the plugin with environment variables

Secrets Safe Ansible components share some common options that can be set via environment variables. The following variables will be need to be set either on the control machine (shell where ansible is called), or within the playbook that uses the plugin:


```
SECRETSSAFE_HOST=<IP address or hostname of Secrets Safe instance>
SECRETSSAFE_PORT=<port of Secrets Safe instance>
SECRETSSAFE_API_KEY=<pregenerated API key>
SECRETSSAFE_APP_NAME=<application name associated with API key>
SECRETSSAFE_VERIFY_CA=<true/false/path to CA certificate>
```

This will allow you to invoke the plugin without the credential/configuration keyword arguments.

***Note* :** The Secrets Safe client verifies the SSL certificate presented by the Secrets Safe instance. The `SECRETSSAFE_VERIFY_CA` environment variable specifies the path to the CA certificate that the Secrets Safe certificate is checked against.

If no `SECRETSSAFE_VERIFY_CA` is specified, the default certificate bundles provided by the python requests library are used.

Certificate verification can be disabled by setting ``SECRETSSAFE_VERIFY_CA=false``. This is strongly discouraged for production environments.


## Common Options

All Secrets Safe Ansible components share some common options:

**name:**

The name of the application used to create the secret

- required: true

**api_key:**

Api key that corresponds to the application provided in the name option

- required: true

**host:**

DNS or IP address of the Secrets Safe instance this secret will be saved to

- required: true

**verify_ca:**

 SSL certificate verification flag. Looks to publicly available CA if set to true.
 - required: false
 - default: true
 - choices:
   - true
   - false
   - path to CA certificate

**port:**

Secrets Safe instance port.
- required: false
- default: 443

---
## secretssafelookup Lookup Plugin

### Description
This module supports retrieving secrets with Secrts Safe.

### Options
In addition to the common options listed above the secretssafelookup plugin also has the following

**uri:**
The Secrets Safe URI where the secret will be retrieved
- required: true

### Examples

#### Retrieve and display multiple secrets from DSS using string arguments.

```
- name: Retrieving and displaying a series of plaintext secrets from Secrets Safe using string arguments.
  hosts: controlnode
  vars:
    secretssafe:
      credentials:
        api_key: "{{ secretssafe_api_key }}"
        app_name: "{{ secretssafe_app_name }}"
      configuration:
        host: "{{ secretssafe_host }}"
        port: "{{ secretssafe_port }}"
        verify_ca: "{{ secretssafe_verify_ca }}"
    uris:
      uri1: some/uri:1
      uri2: some/uri:2

  tasks:
    - name: Call Secrets Safe using jinja2 with_<lookup_plugin_name> syntax
      debug:
        msg: "{{ item }}"
      with_secretssafelookup:
        - 'uri={{ uris.uri1 }} | credentials={{ secretssafe.credentials }} | configuration={{ secretssafe.configuration }}'
        - 'uri={{ uris.uri2 }} | credentials={{ secretssafe.credentials }} | configuration={{ secretssafe.configuration }}'

```


#### Retrieve and display multiple secrets from DSS, reading the configuration from the environment.
```
- name: Retrieving and displaying a series of plaintext secrets from Secrets Safe, reading the configuration/credentials from the environment.
  hosts: controlnode
  vars:
    uris:
      - some/uri:1
      - some/uri:2

  tasks:
    - name: Call Secrets Safe using jinja2 with_<lookup_plugin_name> syntax and pre-exported environment variables
      debug:
        msg: "{{ item }}"
      with_secretssafelookup: "{{ uris }}"

```
#### Retrieve and display a single secret from DSS, reading the configuration from defined variables as keyword arguments.

```
- name: Retrieve and display a single secret from DSS, reading the configuration from defined variables as keyword arguments.
  hosts: controlnode
  vars:
    secretssafe:
      credentials:
        api_key: "{{ secretssafe_api_key }}"
        app_name: "{{ secretssafe_app_name }}"
      configuration:
        host: "{{ secretssafe_host }}"
        port: "{{ secretssafe_port }}"
        verify_ca: "{{ secretssafe_verify_ca }}"
    uri: some/uri:1

  tasks:
      - set_fact:
          decrypted_secret: "{{ lookup('secretssafelookup', uri, credentials=secretssafe.credentials, configuration=secretssafe.configuration) }}"
      - debug:
          msg: "{{ decrypted_secret }}"
```
### Retrieve and display multiple secrets from DSS, reading the configuration from defined variables as keyword arguments.

```
- name: Retrieve and display multiple secrets from DSS, reading the configuration from defined variables as keyword arguments.
  hosts: controlnode
  vars:
    secretssafe:
      credentials:
        api_key: "{{ secretssafe_api_key }}"
        app_name: "{{ secretssafe_app_name }}"
      configuration:
        host: "{{ secretssafe_host }}"
        port: "{{ secretssafe_port }}"
        verify_ca: "{{ secretssafe_verify_ca }}"
    uris:
      - some/uri:1
      - some/uri:2

  tasks:
    - name: Call Secrets Safe lookup in a with_items loop
      debug:
        msg: "{{ lookup('secretssafelookup', item, credentials=secretssafe.credentials, configuration=secretssafe.configuration) }}"
      with_items: "{{ uris }}"
```

---
## create_secret Module

### Description
This module supports creating secrets with Secrts Safe. Secrets can be read from a file on disk or an Ansible fact. Secret creation by providing a generator name is also supported. Credentials for a Secrets Safe application must be provided. 

### Options
In addition to the common options listed above the create_secret module also has the following


**secret_uri:**

The Secrets Safe URI where the secret will be saved
- required: true


**generator:**

Name of generator used to create secret value. Mutually exclusive with **secret_file_path** and **secret_value** options
- required: false 
  

**secret_file_path:**

Path to file that will be saved as a secret. Mutually exclusive with **generator** and **secret_value** options
- required: false
 
**secret_value:**

Value, in the form of a string, that will be saved as a secret Path to file that will be saved as a secret. Mutually exclusive with **generator** and **secret_file_path** options
- required: false

### Examples

#### Create Secret From File
    - name: Create Secret From File
      hosts: managed_1
      tasks:
        - name: Create With File Path
        secretssafe_create:
          api_key: <api_key>
          name: myapp
          host: <secretssafe_host>
          port: 443
          verify_ca: false
          secret_uri: this/is:secret2500
          secret_file_path: /home/lockboxadmin/examples.desktop

#### Create Secret From Fact:
    - name: Create Secret From Fact
      hosts: managed_1
      tasks:
        - name: Set Fact Value
        set_fact:
            test_value: This is my secret
        - name: Create From Fact
          secretssafe_create:
            api_key: <api_key>
            name: myapp
            host: <secretssafe_host>
            port: 443
            verify_ca: false
            secret_value: "{{ test_value }}"
            secret_uri: this/is:secret3          

#### Create Secret From Generator
    - name: Create Secrets Using Generator
      hosts: managed_1
      tasks:
        - name: Create With Generator
        secretssafe_create:
          api_key: <api_key>
          name: myapp
          host: <secretssafe_host>
          port: 443
          verify_ca: true
          generator: my-number-generator
          secret_uri: this/is:secret111        


---
## secretssafe_dynamic_account_create Module

### Description
This module supports creating dynamic accounts with Secrets Safe.

### Options
In addition to the common options listed above the secretssafe_dynamic_account_create module also has the following

**provider:**

Provider used to create the dynamic account

- required: true

**account_definition:**

Account definition used to create the dynamic account

- required: true

**input_file:**

Input file with data for dynamic account creation. Mutually exclusive with **input_json** option

- required: false

**input_json:**

JSON that contains data for dynamic account creation. Mutually exclusive with **input_file** option

- required: false

### Examples
#### Create Dynamic Account and Copy Output to File

```
  - name: Create Dynamic Account and Copy Output to File
    hosts: managed_host_1
    tasks:
    - name: create dynamic account
      secretssafe_dynamic_account_create:
        api_key: 04ab4f29-21c7-4348-98d7
        name: myapp
        host: mydss.myorg.com
        port: 443
        verify_ca: 'false'
        provider: my_gcp_provider
        account_definition: my_gcp_definition
        input_file: path/to/myfile.json
      register: create_output
    - name: copy account info to file
      copy:
        dest: ~/dss_dynamic_account.json
        content: '{{ create_output.msg }}'
```