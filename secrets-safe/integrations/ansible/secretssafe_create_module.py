from __future__ import absolute_import
import sys
import os
from io import StringIO
from ansible.module_utils.basic import AnsibleModule
import secretssafe
import urllib3

ANSIBLE_METADATA = {
    'metadata_version': '1.1',
    'status': ['preview'],
    'supported_by': 'community'
}

DOCUMENTATION = '''
---
module: secretssafe_create

short_description: Create a secret using Secrets Safe

version_added: "2.5.1"

description:
    - "This module supports creating secrets with Secrts Safe. Secrets can be read from a file on disk or an Ansible fact.
       Secret creation by providing a generator name is also supported. Credentials for a Secrets Safe application must be
       provided"

options:
    name:
        description:
            - The name of the application used to create the secret
        required: true
    
    api_key:
        description:
            - Api key that corresponds to the application provided in the name option
        required: true
    
    secret_uri:
        description:
            - The Secrets Safe URI where the secret will be saved
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

    generator:
        description: Name of generator used to create secret value
        required: false

    secret_file_path:
        description: Path to file that will be saved as a secret
        required: false

    secret_value:
        description: Value, in the form of a string, that will be saved as a secret
        required: false
'''

EXAMPLES = '''
    - name: Create With Generator
      secretssafe_create:
        api_key: <api_key>
        name: myapp
        host: <secretssafe_host>
        port: 443
        verify_ca: true
        generator: my-number-generator
        secret_uri: this/is:secret1
    - name: Create With File Path
      secretssafe_create:
        api_key: <api_key>
        name: myapp
        host: <secretssafe_host>
        port: 443
        verify_ca: false
        secret_uri: this/is:secret2
        secret_file_path: /home/myuser/my_certificate.pem
    - name: Set Fact Value
      set_fact:
        secret_value: This is my secret
    - name: Create From Fact
      secretssafe_create:
        api_key: <api_key>
        name: myapp
        host: <secretssafe_host>
        port: 443
        verify_ca: false
        secret_value: "{{ secret_value }}"
        secret_uri: this/is:secret3
'''


def run_module():
    # define available arguments/parameters a user can pass to the module
    module_args = dict(
        api_key=dict(type='str', required=True),
        name=dict(type='str', required=True),
        host=dict(type='str', required=True),
        secret_uri=dict(type='str', required=True),        
        port=dict(type='int', required=False, default=443),
        generator=dict(type='str', required=False),
        verify_ca=dict(type='str', required=False, default='True'),
        secret_value=dict(type='str', required=False),
        secret_file_path=dict(type='str', required=False)
    )

    required_one_args = [['generator', 'secret_value', 'secret_file_path']]
    mutually_exclusive_args = [['generator', 'secret_value', 'secret_file_path']]

    result = dict(
        changed=False,
    )


    module = AnsibleModule(
        argument_spec = module_args,
        supports_check_mode = True,
        required_one_of = required_one_args,
        mutually_exclusive = mutually_exclusive_args
    )

    # if the user is working with this module in only check mode we do not
    # want to make any changes to the environment, just return the current
    # state with no modifications
    if module.check_mode:
        module.exit_json(**result)

    host = module.params['host']
    app_name = module.params['name']
    api_key = module.params['api_key']
    verify_ca = module.params['verify_ca']
    port = module.params['port']
    generator = module.params['generator']
    secret_value = module.params['secret_value']
    secret_file_path = module.params['secret_file_path']    
    secret_uri = module.params['secret_uri']

    if str(verify_ca).lower() == 'false':
        # verify_ca = False
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    client = secretssafe.create_client(host, port, verify_ca)
    
    auth_success, auth_error = client.authenticate_application(api_key, app_name)
    # authentication failed
    if not auth_success:
        result['failed'] = True
        result['msg'] = auth_error
        module.fail_json(**result)

    try:
        cli_output = None
        if generator is not None:
            cli_output = client.create_secret_using_generator(secret_uri, generator)
        elif secret_file_path is not None:
            cli_output = client.create_secret_from_file(secret_uri, secret_file_path)
        elif secret_value is not None:
            secret_value = secret_value.encode()
            cli_output = client.create_secret(secret_uri, secret_value)

        
        if isinstance(cli_output, bool) and cli_output:
            result['changed'] = True
            result['msg'] = 'Secret successfully saved at {}'.format(secret_uri)
            module.exit_json(**result)
        else:
            result['failed'] = True
            result['msg'] = cli_output
            module.fail_json(**result)

    except Exception as ex:
        result['failed'] = True
        module.fail_json(msg='An error occured attempting to create secret at {} - {}'.format(secret_uri, str(ex)), **result)
        


def main():
    run_module()

if __name__ == '__main__':
    main()