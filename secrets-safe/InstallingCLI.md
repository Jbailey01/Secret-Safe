Installing the Secrets Safe CLI <!-- omit in toc -->
============================

The Secrets Safe CLI, ssrun, is a python package that wraps functionality exposed by the Secrets Safe API into a convenient tool
used to interact with the system.

# Table Of Contents <!-- omit in toc -->

- [Prerequisite](#prerequisite)
- [Installing the package with pip](#installing-the-package-with-pip)
- [Executing the CLI](#executing-the-cli)
- [Configuring the initial context](#configuring-the-initial-context)
- [Bash autocompletion](#bash-autocompletion)

# Prerequisite

The Secrets Safe CLI should run on any major platforms supported by python and which have python 3.6 and pip3 or above available.

# Installing the package with pip

The Secrets Safe CLI package, titled secretssafe, is installed and managed on a client machine by the python package manager [pip](https://pip.pypa.io/en/stable/) through a BeyondTrust supplied .whl file that is located in the CommandLineInterface directory of the extracted archive.

Execute the following when running in a virtual environment:

``$ pip install secretssafe-<version>-py3-none-any.whl``

Conversely, execute the following when running outside a virtual environment:

``$ pip3 install secretssafe-<version>-py3-none-any.whl``

# Executing the CLI

After a successful installation, the CLI may be run by executing the following from any location on the filesystem:

```
$ ssrun
```

***Note* :** If the secretssafe package was installed inside a virtual environment, the environment must be first activated for `ssrun` to be on the path and thus executable.

# Configuring the initial context

Contexts allow for multiple Secrets Safe instances to be easily configured and accessed from a single client machine. On preliminary installation, execute the following to be prompted for details of the initial context:

```
$ ssrun context create
```

Follow the prompts to configure the Secrets Safe instance that the CLI will initially interact with. To view your configured clusters, execute the following:

```
$ ssrun context get
CURRENT    NAME       HOSTNAME/IP      PORT  API VERSION    SSL CA
*          localhost  localhost        8443  v1             false
```

Your initial context will be set to current (configuration in which to use during any other CLI action) on creation, and any subsequent contexts created may be configured as current with the following command:

```
$ ssrun context set-current -n <context_name>
```

In addition, specific environment variables may be used to override the current context:

```
$ export SECRETSSAFE_HOST=<IP address or hostname of Secrets Safe instance>
$ export SECRETSSAFE_PORT=<port of Secrets Safe instance>
```

***Note* :** The following variable is necessary only if the certificate authority is not publicly trusted.

```
$ export SECRETSSAFE_VERIFY_CA=<path_to_ca_cert>
```

***Note* :** The Secrets Safe CLI verifies the SSL certificate presented by the Secrets Safe instance. The `SECRETSSAFE_VERIFY_CA` environment variable or `SSL CA` context attribute specifies the path to the CA certificate that the Secrets Safe certificate is checked against.

If no `SECRETSSAFE_VERIFY_CA` is specified, the default certificate bundles provided by the python requests library are used.

Certificate verification can be disabled by setting ``SECRETSSAFE_VERIFY_CA=false``. This is strongly discouraged for production environments.

To utilize these environment variables by default rather than manually managing contexts, they may be persisted in the shell environment. For example storing them in a users ~/.bashrc file similar to the following;

```
$ echo 'export SECRETSSAFE_HOST=1.1.1.1' >> ~/.bashrc
$ echo 'export SECRETSSAFE_PORT=443' >> ~/.bashrc
$ echo 'export SECRETSSAFE_VERIFY_CA=false' >> ~/.bashrc
$ source ~/.bashrc
```

***Note* :** In the example above certificate verification has been set to false. While this is convenient for test it is NOT recommended in a production environment.

# Bash autocompletion

The Secrets Safe CLI comes with the ability to configure bash autocompletion for ease of use and convenience. To install bash completion globally, execute the following:

```
$ ssrun completion bash > /etc/bash_completion.d/ssrun
```

This will allow any new bash instances to autocomplete the Secrets Safe CLI commands on demand. Sudo rights may be required to be able to write to `/etc/bash_completion.d/`.
