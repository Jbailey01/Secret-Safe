# Secrets Safe Puppet Module Developer Guide

Note this guide assumes you already have a Puppet Master node set up with at least one agent. The rest-client gem must also be installed for the master. This also assumes you have a running instance of Secrets Safe and an application that has permissions to perform operations you require.

In order to make your master node aware of the Secrets Safe module you must copy the module contents to your master node's modules directory in the appropriate environment. 

For example using the default environment of production:
```
scp -r secrets_safe <your_user>@<master node ip>:/etc/puppetlabs/code/environments/production/modules
```

Next you will want to create a module that uses the secrets safe module. For example:
```
mkdir -p /etc/puppetlabs/code/environments/production/modules/my_test_module/manifests/
```

Then create a init file that uses Secrets Safe:
```
vim /etc/puppetlabs/code/environments/production/modules/my_test_module/manifests/init.pp

# paste the following:

   $secret_val = dss_get_secret('https://your_secrets_safe_instance', 'my_scope:my_secret', "my_application", "my_api_key")
   notify {"the secret from get_secret() is ${secret_val} ":}

```

Finally edit your site.pp file to include the test module for the agent node you are connecting from:
```
vim /etc/puppetlabs/code/environments/production/manifests/site.pp

# paste the following:
node 'your-agent-node-here' {
  include my_test_module
}

```

From here you should be able to run `puppet agent -t` on your agent node and see the notify message. When you want to update the Secrets Safe module source you will need to copy the files back up to the module directory.
