from __future__ import absolute_import
import sys
import os
from io import StringIO
from ansible.module_utils.basic import AnsibleModule
import secretssafe
from json import JSONDecodeError
import json
import urllib3

ANSIBLE_METADATA = {
    'metadata_version': '1.0',
    'status': ['preview'],
    'supported_by': 'community'
}

DOCUMENTATION = '''
---
module: secretssafe_dynamic_account_create

short_description: Create a dynamic account

version_added: "2.5.1"

description:
    - "This module supports creating dynamic accounts with Secrets Safe"

options:

    name:
        description:
            - The name of the application used to create the secret
        required: true
    
    api_key:
        description:
            - Api key that corresponds to the application provided in the name option
        required: true
    
    host:
        description:
            - DNS or IP address of the Secrets Safe instance this secret will be saved to
        required: true
    
    verify_ca:
        description:
            - SSL certificate verification flag
            - looks to publicly available CA if set to true.
        required: false
        default: true
        choices:
            - true
            - false
            - path to CA certificate
    
    port:
        description: Secrets Safe instance port.
        required: false
        default: 443

    provider:
        description:
            - Provider used to create the dynamic account
        required: true
    
    account_definition:
        description:
            - Account definition used to create the dynamic account
        required: true

    input_file:
        description:
            - Input file with data for dynamic account creation
        required: false

    input_json:
        description:
            - Json that contains data for dynamic account creation
        required: false

'''

EXAMPLES = '''
  - name: Create Dynamic Account and Copy Output to File
    hosts: localhost
    tasks:
    - name: create dynamic account
      secretssafe_dynamic_account_create:
        api_key: 04ab4f29-21c7-4348-98d7
        name: myapp
        host: localhost
        port: 443
        verify_ca: 'false'
        provider: my_gcp_provider
        account_definition: my_gcp_definition
      register: create_output
    - name: copy account info to file
      copy:
        dest: ~/dss_dynamic_account.json
        content: '{{ create_output.msg }}'

  - name: Create Dynamic Account With JSON Input
    hosts: localhost
    tasks:
    - name: create dynamic account
      secretssafe_dynamic_account_create:
        api_key: 04ab4f29-21c7-4348-98d7
        name: myapp
        host: localhost
        port: 443
        verify_ca: 'false'
        provider: my_gcp_provider
        account_definition: my_gcp_definition
        input_json: '{"name": "my new account"}'
'''


def run_module():
    # define available arguments/parameters a user can pass to the module
    module_args = dict(
        api_key=dict(type='str', required=True),
        name=dict(type='str', required=True),
        host=dict(type='str', required=True),  
        port=dict(type='int', required=False, default=443),
        verify_ca=dict(type='str', required=False, default='True'),        
        provider=dict(type='str', required=True),
        account_definition=dict(type='str', required=True),
        input_file=dict(type='str', required=False),
        input_json=dict(type='str', required=False)
    )

    mutually_exclusive_args = [['input_file', 'input_json']]

    result = dict(
        changed=False,
    )

    module = AnsibleModule(
        argument_spec = module_args,
        supports_check_mode = True,
        mutually_exclusive = mutually_exclusive_args
    )

    # if the user is working with this module in only check mode we do not
    # want to make any changes to the environment, just return the current
    # state with no modifications
    if module.check_mode:
        module.exit_json(**result)

    input_json = module.params['input_json']
    host = module.params['host']
    app_name = module.params['name']
    api_key = module.params['api_key']
    verify_ca = module.params['verify_ca']
    port = module.params['port']

    provider = module.params['provider']
    account_definition = module.params['account_definition']
    input_file = module.params['input_file']

    # handle auto-converting Ansible does and disable warning if verify_ca is false
    if str(verify_ca).lower() == 'false':
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    if input_json:
        try:
            json.loads(input_json)
        except json.JSONDecodeError:
            result['failed'] = True
            result['msg'] = 'input_json is not valid JSON'
            module.fail_json(**result)

    client = secretssafe.create_client(host, port, verify_ca)

    auth_success, auth_error = client.authenticate_application(api_key, app_name)
    # authentication failed
    if not auth_success:
        result['failed'] = True
        result['msg'] = auth_error
        module.fail_json(**result)

    try:
        if input_json:
            success, response = client.create_dynamic_account_with_json(provider, account_definition, input_json)
        else:
            success, response = client.create_dynamic_account(provider, account_definition, input_file)
        if success:
            result['changed'] = True
            result['msg'] = response
            module.exit_json(**result)
        else:
            result['failed'] = True
            result['msg'] = response
            module.fail_json(**result)

    except Exception as ex:
        result['failed'] = True
        module.fail_json(msg='An error occured attempting to create dynamic account: {}'.format(str(ex)), **result)
        

def main():
    run_module()

if __name__ == '__main__':
    main()