# python 3 headers, required if submitting to Ansible
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = '''
    lookup: secretssafelookup
    author: Andrew Welsman <awelsman@beyondtrust.com>
    version_added: "1.0"
    short_description: Retrieve secrets from BeyondTrust's Secrets Safe
    description: Retrieve secrets from BeyondTrust's Secrets Safe
    requirements:
    - secretssafe (python library)
    options:
        host:
            description: Secrets Safe instance hostname or IP.
            required: True
        port:
            description: Secrets Safe instance port.
            required: True
        verify_ca:
            description:
                - SSL certificate verification flag
                - looks to publicly available CA if set to true.
            required: True
            choices:
                - true
                - false
                - path to CA certificate
        api_key:
            description: API key for authentication.
            required: True
        app_name:
            description: application name associated with API key.
            required: True
        uri:
            description: URI of the secret to retrieve.
            required: True

'''
import ast
import os
from ansible.errors import AnsibleError, AnsibleParserError
from ansible.plugins.lookup import LookupBase
from ansible.utils.display import Display
from ansible.module_utils._text import to_text

HAS_SECRETSSAFE = False
try:
    import secretssafe
    HAS_SECRETSSAFE = True
except ImportError:
    HAS_SECRETSSAFE = False


display = Display()

CREDENTIALS = 'credentials'
CONFIGURATION = 'configuration'
SECRETSSAFE_VARS = [CREDENTIALS, CONFIGURATION]

API_KEY = 'api_key'
APP_NAME = 'app_name'
CRED_VARS = [API_KEY, APP_NAME]

HOST = 'host'
PORT = 'port'
VERIFY_CA = 'verify_ca'
CONFIG_VARS = [HOST, PORT, VERIFY_CA]

def _check_env():
    for var in CRED_VARS + CONFIG_VARS:
        if not os.getenv('SECRETSSAFE_' + var.upper()):
            return False
    return True

def _read_env():
    return (os.getenv('SECRETSSAFE_' + HOST.upper()),
            os.getenv('SECRETSSAFE_' + PORT.upper()),
            os.getenv('SECRETSSAFE_' + VERIFY_CA.upper()),
            os.getenv('SECRETSSAFE_' + API_KEY.upper()),
            os.getenv('SECRETSSAFE_' + APP_NAME.upper()))

def _read_vars(**kwargs):

    if not all(var in kwargs for var in SECRETSSAFE_VARS):
        raise AnsibleError(f'Incompatible keyword arguments: {kwargs}')

    credentials = kwargs[CREDENTIALS]
    configuration = kwargs[CONFIGURATION]

    if not all(cred in credentials for cred in CRED_VARS):
        raise AnsibleError(f'Incomplete credentials: {credentials}')

    if not all(config in configuration for config in CONFIG_VARS):
        raise AnsibleError(f'Incomplete configuration: {configuration}')

    return (configuration[HOST],
            configuration[PORT],
            configuration[VERIFY_CA],
            credentials[API_KEY],
            credentials[APP_NAME])

def _format_args(terms, **kwargs):

    def _split_kv_pair(param):
        try:
            key, value = param.split('=')
        except ValueError:
            raise AnsibleError(('secretssafe lookup plugin needs '
                                'key=value pairs, but received '
                                f'{terms}'))
        return key, value

    # parse kwargs from terms
    for param in terms[0].split('|'):
        key, value = _split_kv_pair(param)
        if key != 'uri':
            kwargs[key.strip()] = ast.literal_eval(value.strip())
    # parse uris
    uris = []
    for term in terms:
        for param in term.split('|'):
            key, value = _split_kv_pair(param)
            if key == 'uri':
                uris.append(value.strip())
    return uris, kwargs

def _assign_vars(terms, **kwargs):
    uris = terms
    env_configured = _check_env()
    if env_configured:
        host, port, verify_ca, api_key, app_name = _read_env()
    if kwargs:
        # any variables handed in as keyword arguments override environment
        if set(kwargs.keys()) == {'wantlist'}:
            if not env_configured:
                uris, kwargs = _format_args(terms, **kwargs)
            kwargs.pop('wantlist')
        # if kwargs still exist, read variables from them
        if kwargs:
            host, port, verify_ca, api_key, app_name = _read_vars(**kwargs)
    return host, port, verify_ca, api_key, app_name, uris

class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        if not HAS_SECRETSSAFE:
            raise AnsibleError(('Please pip install secretssafe to use the '
                                'secretssafe lookup plugin.'))

        # Plugin invoked either using:
        # 1) terms = uri, and configuration/credentials = kwargs, or
        # 2) terms = uri, configuration/credentials = environment variables, or
        # 3) all parsed from pure string args
        host, port, verify_ca, api_key, app_name, uris = _assign_vars(terms, **kwargs)

        # create client and authenticate application
        client = secretssafe.create_client(host, port, verify_ca)
        client.authenticate_application(api_key, app_name)

        secrets = []
        for uri in uris:
            display.vvvv(f'Retrieving secret {uri}')
            secret = client.retrieve_secret(uri)
            if not secret:
                raise AnsibleError("could not read secret at uri: %s" % uri)
            secrets.append(to_text(secret))
        return secrets
