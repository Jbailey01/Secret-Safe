# DevOps Secrets Safe / Jenkins Plugin Installation Guide


## Installation

The plugin is packaged as a self-contained .hpi file which can be installed either from the web UI or via the Jenkins CLI.  Once you have acquired the file, ***devops-secrets-safe.hpi***, proceed with one of the following installation methods.  *(More info can be found [here](https://jenkins.io/doc/book/managing/plugins/))*

### Via Jenkins web UI

The most common method for plugin installation and administration is to use the web UI.  Authenticate as a user with administrative permissions and navigate to **Manage Jenkins > Manage Plugins**.

Once there, select the **Advanced** tab and scroll down to the **Upload Plugin** section.

Click **Choose File** to browse to and select your .hpi file.

Finally, click **Upload** and allow Jenkins to restart once installation has finished.

### Via the Jenkins CLI

The Jenkins CLI can also be leveraged for many administrative tasks including plugin installation.  To install via the CLI, execute a command similar to:

```bash
java -jar jenkins-cli.jar -s "http://your-jenkins-server:8080/" install-plugin "path/to/devops-secrets-safe.hpi" -deploy -restart
```


## Configuration

First, it is important to note that the plugin can configured at any or all of the available scopes within a Jenkins environment.  This means that configuration can exist at the global level (**Manage Jenkins > Configure System**), at the folder level, or at the individual item / project level.

When a build job executes, configuration is resolved starting at the most specific scope and working back up the chain until a valid (i.e. fully-populated) configuration is found - *item level > folder level (through multiple folder levels if present) > global level*.

The specific information collected for configuration includes the following fields:

- **Name / Alias** - Provides a place to give a quick, descriptive name to the collection of settings
- **DSS URL** - The base URL of the DSS instance including protocol, hostname or IP, and port
- **DSS Application Credentials** - The application credentials used to authenticate to the DSS RESTful APIs ... more on this below
- **Skip SSL Validation** - If enabled, the plugin will skip validation of any SSL cert presented by the DSS instance during the execution of RESTful API calls

The credentials used for authentication to the DSS instance are stored in the Jenkins internal credential store and read at the time of job execution.  They are stored as a custom credential type named DSS Application Credentials which require an ***Application Name*** and ***API Key*** matching a configured principal within DSS.


## Usage

Secrets are retrieved from DevOps Secrets Safe for use in a build based on information provided in each project's build configuration, injected as environment variables, and intentionally limited in scope to help avoid exposing them outside of where they are actually used.

The following is an example of the configuration necessary to retrieve and use secrets within a build process:

```groovy
def requestedSecrets = [
    [ secretUri: 'full/scope/path:git-user', environmentVariable: 'gitPwd' ],
    [ secretUri: 'full/scope/path:admin-user', environmentVariable: 'adminPwd' ]
];
withDss(requestedSecrets: requestedSecrets) {
    // ..... do some build stuff
    bat my_program.exe -u git-user -p ${env.gitPwd}
    // ..... more build stuff
    bat my_other_program.exe --administratorPassword "${env.adminPwd}"
}
```

In the above example, the ***withDss*** block defines the scope within which the secrets will be available and initiates the retrieval of those secrets.  The required parameter for the withDss() {...} is ***requestedSecrets*** which should be supplied with an array of secrets you wish to retrieve and use within the block.

The individual entries in the ***requestedSecrets*** array should contain two properties:

- **secretUri** - The full path / scope for the secret followed by a colon and the secret name
- **environmentVariable** - The environment variable name by which you'd like to reference the secret value within the block

To access the secret values, simply reference them as you would any other environment variable in your script:  *${env.variable-name}*

*NOTE: The values are also accessible via the secret URI as follows:  ${env.'full/scope/path:secret-name'}*

Again, the values are only available within the withDss block and will be retrieved from DevOps Secrets Safe using the most specific configuration that can be resolved by the plugin for the given job.