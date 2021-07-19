Getting Started with Secrets Safe <!-- omit in toc -->
============================

Learn the basics of using and interacting with Secrets Safe via the ssrun CLI. This guide covers the basics required to get you up and running.

# Table Of Contents <!-- omit in toc -->

- [Initializing Secrets Safe](#initializing-secrets-safe)
- [Managing Users](#managing-users)
  - [Resource Name Restrictions](#resource-name-restrictions)
- [Managing Applications](#managing-applications)
- [Managing Secrets and Scopes](#managing-secrets-and-scopes)
  - [Secret and Scope Maximums](#secret-and-scope-maximums)
- [Managing Metadata](#managing-metadata)
- [Managing Safelists and IP ranges](#managing-safelists-and-ip-ranges)
      - [*Safelist model*](#safelist-model)
      - [*IP range model*](#ip-range-model)
- [Nginx Ingress Installation Requirements for Safelist Capability](#nginx-ingress-installation-requirements-for-safelist-capability)
- [Managing Event Sink Configurations](#managing-event-sink-configurations)
- [Managing Secrets Safe CLI Contexts](#managing-secrets-safe-cli-contexts)
      - [*Note on CLI Context and Environment Variables*](#note-on-cli-context-and-environment-variables)



# Initializing Secrets Safe

**Prerequisite: Before starting this section, ensure a new instance of Secrets Safe is running and the Secrets Safe CLI is configured to communicate with it as detailed in '[Installing the Secrets Safe CLI'](InstallingCLI.md) section.**

Step 1 - Initialize Secrets Safe: 

``$ ssrun init``

Set the desired password for the root user account in the Secrets Safe instance when prompted. The password must be at least 10 characters in length.
**A successful call to init returns the master key for this Secrets Safe instance. Save this key to a file.**
NOTE: The remainder of this guide assumes that the root account password for the Secrets Safe instance has been set to rootpassword and that the master key has been saved to a file called master.txt

Step 2 - Unseal Secrets Safe:

``$ ssrun unseal -f master.txt``

All CLI commands aside from Initialize and Unseal will be unavailable until the instance is unsealed.  This command will put the Secrets Safe application into a state where secrets may be saved and retrieved.

Step 3 - Log in to Secrets Safe as root: 

``$ ssrun login -u root -p rootpassword``


# Managing Users

**Prerequisite: Before starting this section, ensure you have initialized, unsealed, and logged into Secrets Safe as root as detailed in the [Initializing Secrets Safe](#initializing-secrets-safe) section.**

Step 1 - Create a new user: 

``$ ssrun user create -n NewUser -p NewUserPassword``

**Note: passwords must be at least 10 characters in length.**

Step 2 - View the list of users: 

``$ ssrun user get -v``

**Note: At the API the principal discovery mechanism accepts any subset of the uri {identity_provider}/{principal_type}/{principal_name}/{principal_extension_data}. The command above will return all internal users by passing 'internal/user'.  Additionally, the (optional) -v flag can be used to get a full listing of principals or principal containers attributes. Otherwise, a slim view of each principal or principal container is returned.**

Step 3 - Create a secret (note that the 'echo' line may only be
performed in bash and similar shells):

``$ echo -n "I love my test content" | ssrun secret create testsecret:mytestsecret``

**Note: Whenever you reference a secret, the URI must be in the format '{scopePath}:{secretName}'.  For example, path/to/secrets:secretName.  For more information on managing secrets see [Managing Secrets and Scopes](#managing-secrets-and-scopes)**

Step 5 - Authorize the new user to read the secret:

``$ ssrun authorization create -p principal/internal/user/NewUser -o read -a allow secret/testsecret:mytestsecret``

**Note: The create-authorization command accepts the following arguments.**

*-p (Required)* URI of the principal the access control is being applied to.  A user's URI can be derived using the principal discovery mechanism detailed in step 2.
*-o (Optional)* Operations authorization applies to.  Options are create|read|update|delete|grant
*-a (Optional)* Set to allow to authorize or deny to revoke. **

Step 6 - Log in as the new user: 

``$ ssrun login -u NewUser -p NewUserPassword``

Step 7 - Read the secret: 

``$ ssrun secret get testsecret:mytestsecret``

Step 8 - Login as root again:

``$ ssrun login -u root -p rootpassword``

Step 9 - Delete the new user:

``$ ssrun user delete -n NewUser``

## Resource Name Restrictions

DSS enforces restrictions for all resource types. 

The valid characters for resources at large are:
`abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@:$_.+!*'()-`

Additionally there are specific restrictions on user, application, and group names. 

The maximum number of characters in any user, application, or group name is 120. 

The valid characters for user, application, and group names are:
`abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._@+`

# Managing Applications

**Prerequisite: Before starting this section, ensure you have initialized, unsealed, and logged into Secrets Safe as root as detailed in the [Initializing Secrets Safe](#initializing-secrets-safe) section.**

Step 1 - Create a new application: 

``$ ssrun application create -n NewApplication``

**Note: Upon creation, an api key will be returned. This will be used in any subsequent log in.**

Step 2 - View the list of applications:

``$ ssrun application get -v``

**Note: At the API the principal discovery mechanism accepts any subset of the uri {identity_provider}/{principal_type}/{principal_name}/{principal_extension_data}. The command above will return all internal applications by passing 'internal/application'.  Additionally, the (optional) -v flag can be used to get a full listing of principals or principal containers attributes. Otherwise, a slim view of each principal or principal container is returned.**

Step 3 - Create a secret (note that the 'echo' line may only be performed in bash and similar shells):

``$ echo -n "I love my test content" | ssrun secret create testsecret:mytestsecret``

**Note: Whenever you reference a secret, the URI must be in the format '{scopePath}:{secretName}'.  For example, path/to/secrets:secretName.  For more information on managing secrets see [Managing Secrets and Scopes](#managing-secrets-and-scopes)**

Step 5 - Authorize the new application to read the secret:

``$ ssrun authorization create -p principal/internal/application/NewApplication -o read -a allow secret/testsecret:mytestsecret``
**Note: The authorize command accepts the following arguments:**
*-p (Required)* URI of the principal the access control is being applied to. An applications URI can be derived using the principal discovery mechanism detailed in step 2.
*-o (Optional)* Operations authorization applies to. Options are create|read|update|delete|grant.
*-a (Optional)* Set to allow to authorize or deny to revoke. Options are allow|deny.

Step 6 - Log in as the new application:

``$ ssrun login -a NewApplication -k 2a098f21-0b11-4918-b705-7752588d5d8c``

**Note: The api key (-k) comes from what was returned when the application was created (see step 1).**

Step 7 - Read the secret: 

``$ ssrun secret get testsecret:mytestsecret``

Step 8 - Login as root again:

``$ ssrun login -u root -p rootpassword``

Step 9 - Delete the new application:

``$ ssrun application delete -n NewApplication``

**Note: The name associated with an application can be determined via the list applications command (see step 2).

# Managing Secrets and Scopes

**Prerequisite: Before starting this section, ensure you have initialized, unsealed, and logged into Secrets Safe as root as detailed in the [Initializing Secrets Safe](#initializing-secrets-safe) section.**

(The next example assumes there are two files called *myTestSecretData1.txt and myTestSecretData2.txt* containing data you want to be stored as a secret.)

Step 1 - Create two secrets: 

``$ ssrun secret create -f myTestSecretData1.txt path/to/my/secrets:mytestsecret1``

``$ ssrun secret create -f myTestSecretData2.txt path/to/my/secrets:mytestsecret2``

**Note: Whenever you reference a secret, the URI must be in the format {scopePath}:{secretName}.  For example, path/of/scope:secretName**

Step 2 - Retrieve the list of secret names for a given scope:

``$ ssrun scope get path/to/my/secrets``

(The next example assumes there is a file called *updatedMyTestSecretData1.txt* containing the data you want to use to update this secret.)

Step 3 - Update a secret:

``$ ssrun secret update -f updatedMyTestSecretData1.txt path/to/my/secrets:mytestsecret1``

Step 4 - Retrieve a secret:

``$ ssrun secret get path/to/my/secrets:mytestsecret1``

Step 5 - Retrieve all secrets under a scope and save them in the directory "my_secret_dir"  
``$ ssrun secret get path/to/my/secrets -d my_secret_dir``

Step 6 - Remove a secret:

``$ ssrun secret delete path/to/my/secrets:mytestsecret1``
**Note: This will not only remove the secret but also all metadata that is associated with it.**

Step 7 - Remove a scope:

``$ ssrun scope delete path/to/my/secrets``
**Note: This will not only remove the scope but also all scopes, secrets and metadata that are children of it.**

## Secret and Scope Maximums

DSS enforces a maximum size for secret and scope names.

The maximum number of characters in any path segment is 1024. A segment is a string between two forward-slash (`/`) characters.

The maximum number of segments in any scope path is 100.

# Managing Metadata

**Prerequisite: Before starting this section, ensure you have initialized, unsealed, and logged into Secrets Safe as root as detailed in the [Initializing Secrets Safe](#initializing-secrets-safe) section.**
**Note: Metadata is currently supported for secret and scope resource types.**

Step 1 - Create metadata for a secret

``$ ssrun metadata create -n mytestsecret1Meta1Name -v meta1Value secret/path/to/my/secrets:mytestsecret1``
**Note: When managing metadata, to reference a secret or scope, use the full URI.  For example, secret/path/of/scope or secret/path/of/scope:secretName**

Step 2 - Update metadata for a secret

``$ ssrun metadata update -n mytestsecret1Meta1Name -v updatedMeta1Value secret/path/to/my/secrets:mytestsecret1``

Step 3 - View metadata for a secret

``$ ssrun metadata get -n mytestsecret1Meta1Name secret/path/to/my/secrets:mytestsecret1``
**Note:  The above command will retrieve the value specifically associated with the metadata item named 'mytestsecret1Meta1Name'.  To retrieve the information for all metadata items associated with a scope or secret omit the -n argument.**

Step 4 - Remove metadata:

``$ ssrun metadata delete -n mytestsecret1Meta1Name secret/path/to/my/secrets:mytestsecret1``

# Managing Safelists and IP ranges

**Prerequisite: Before starting this section, ensure you have initialized, unsealed, and logged into Secrets Safe as root as detailed in the [Initializing Secrets Safe](#initializing-secrets-safe) section.**

Safelists allow you to explicitly grant or deny access to specific IP addresses for all commands sent to the API.  Safelists and IP ranges must be structured in the following way:

#### *Safelist model*

*Name - (Required)* Name for this safelist.
*Description - (Optional)* Details about this safelist
*Expiry date - (Optional)* Specifies a day and time when this safeList will expire. An empty or null value denotes no expiry.

#### *IP range model*

A safelist must have at least one IP range associated with it.

*Name - (Required)* Name for this IP range.
*Value - (Required)* Specifies a range of IP addresses. The supported IP range value patterns are:
       CIDR range: "192.168.0.0/24", “fe80::%lo0/10”
       Single address: "10.101.8.16", “fe80::1%23”
       Begin-end range: "10.101.8.10-10.101.8.20", “fe80::1%23-fe80::ff%23”
*Allow - (Required)* Specifies whether the defined range of IP addresses should be used to allow or deny access.
*Description - (Optional)* Details about this IP range
*Expiry date - (Optional)* Specifies a day and time when this IP range will expire. An empty or null value denotes no expiry.

Step 1 Create two safelists

``$ ssrun safelist create -f safelist1.txt``

``$ ssrun safelist create -f safelist2.txt``

This example assumes there are two files called *safelist1.txt and safelist2.txt* with the following contents:

 
**safelist1.txt**

```
{
   "ipRanges": [
      {
         "name": "ip_range_1",
         "value": "10.101.8.10-10.101.8.20",
         "allow": true,
         "description": "IP Range 1 Description",
         "expiryDate": "2020-06-21T11:44:31.733Z",
         "xForwardedForHeaderLimit": "2"
      }
   ],
   "name": "safelist_1",
   "description": "Safelist 1 Description",
   "expiryDate": "2020-06-21T11:44:31.733Z"
}
```
**Note: In the above example, the safelist will only be enforced until the defined expiry date and will allow only IP addresses in the range of 10.101.8.10 to 10.101.8.20.**

**safelist2.txt**

```
{
   "ipRanges": [
      {
         "name": "ip_range_2",
         "value": "10.101.8.50-10.101.8.60",
         "allow": false,
         "description": "IP Range 2 Description"
      }
   ],
   "name": "safelist_2",
   "description": "Safelist 2 Description"
}
```
**Note: In the above example, the safelist will never expire and will deny IP addresses in the range of 10.101.8.50 to 10.101.8.60.**

Step 2 - Viewing safelists and ip ranges:

The ```safelist get``` command will return all safelists that exist.

``$ ssrun safelist get``

***Optionally*:** you can limit the view by passing in the name of the safelist targeted for discovery.

``$ ssrun safelist get -n safelist_1``

The ```ip-range get``` command will return all the ip ranges that exist for a given safelist.

``$ ssrun ip-range get -n safelist_1``

***Optionally*:** you can limit the view by passing in the name of the ip range targeted for discovery.

``$ ssrun ip-range get -n safelist_1 -i ip_range_1``

These views can be further modified by using the following flags:

```-d``` (*Depth*) Use this to define the maximum depth of the view to return. A value of 0 returns only the element specified. A value of 1 returns the element specified and all direct children. A value of 2 returns all children and grandchildren of the element specified.

```-v``` (*Verbose*) Use this to get a full listing of safelists and/or ip ranges attributes. Otherwise, a slim view of each safeLists and/or ip ranges is returned

Step 3 - Update a safelist:

``$ ssrun safelist update -n safelist_2 -f safelist2Update.txt``

This command will update the safelist with name safelist_2.  The example assumes there is a file called *safelist2Update.txt* with the following contents:

**safelist2Update.txt**

```
{
    "description": "Safelist 2 Description Updated",
    "expiryDate": "2021-06-21T12:17:14.326Z"
}
```

Step 4 - Add an IP range to a safelist:

``$ ssrun ip-range create -n safelist_2 -f ipRange.txt``

This command will add an IP range to the safelist with name safelist_2.  The example assumes there is a file called *ipRange.txt* with the following contents:

**ipRange.txt**

```
{
    "value": "10.101.8.70",
    "allow": false,
    "description": "IP Range 3 Description",
    "expiryDate": "2021-06-21T11:58:03.315Z"
}
```
**Note: In the above example, the IP range will only be enforced until the defined expiry date and will deny IP requests coming from the IP address 10.101.8.70**

Step 5 - Update an IP range of a safelist

``$ ssrun ip-range update -n safelist_2 -i ip_range_2 -f ipRangeUpdate.txt``

This command will update the IP range with name ip_range_2 for the safelist with name safelist_2.  The example assumes there is a file called *ipRangeUpdate.txt* with the following contents:

**ipRangeUpdate.txt**

```
{
    "value": "10.101.8.71",
    "allow": false,
    "description": "IP Range 3 Updated",
    "expiryDate": "2021-06-21T11:58:03.315Z"
}
```

Step 6 - Assign a safelist to a user

``$ ssrun authorization create -p principal/internal/user/user1 -o read -a allow safelist/safelist_2/access``

This command will associate the safelist with name safelist_2 to the user with name user1.

Step 7 - Delete an IP range from a safelist

``$ ssrun ip-range delete -n safelist_2 -i ip_range_2``

This command will delete the IP range with name ip_range_2 from the safelist with name safelist_2

Step 8 - Delete a safelist

``$ ssrun safelist delete -n safelist_2``

This command will delete the safelist with name safelist_2

# Nginx Ingress Installation Requirements for Safelist Capability

Currently the Secrets Safe application is compatible with the Nginx Ingress Controller. (found at https://charts.helm.sh/stable)

If you wish to install this ingress controller from the official helm chart for a bare metal deployment the following command may be run: 
```helm install ingress-nginx ingress-nginx/ingress-nginx --namespace kube-system --set controller.hostNetwork=true --set rbac.create=true --set controller.kind=DaemonSet --version 3.24.0```

If you wish to install this ingress controller from the official helm chart for an Azure deployment the following command may be run: 
```helm install ingress-nginx ingress-nginx/ingress-nginx --namespace kube-system --set controller.service.externalTrafficPolicy=Local --set controller.replicaCount=3 --version 3.24.0```

**Note:** The ```--set controller.service.externalTrafficPolicy=Local``` option is added to the Helm install command for safelist enforcement purposes. This will enable client source IP preservation for requests to containers in your cluster.  If you are not planning on using safelist enforcement, this option can be excluded.

# Managing Event Sink Configurations

Create an event sink configuration ``ssrun event-sink create -f myconfig.json`` This command creates an event sink configuration using the provided json file Detailed instructions on event sink configuration can be found [in the event sink configuration section](Configuration/EventSinks.md) of the documentation.

# Managing Secrets Safe CLI Contexts

Contexts are cli-specific configurations that allow you to access multiple instance of Secrets Safe from a single client machine
CLI contexts exist only on the client side and only tell the CLI where to access the Secrets Safe instance they do not interact with the instance in any way on their own.

Here is some example usage of contexts. Let's assume you want to interact with two instances of Secrets Safe - one in staging and one in production. 
You want to take the value of a secret from your staging Secrets Safe and save it to your production instance. In this example your staging instance has an ip of 164.223.32.59 and your production instance has an ip of 164.225.37.62

Step 1 - Create a context pointing at staging

``$ ssrun context create -n staging -a 164.223.32.59 -p 443 -s false -v v1``

Step 2 - Create a context pointing at production

``$ ssrun context create -n production -a 164.225.37.62 -p 443 -s true -v v1``

Step 3 - Set the staging context to active

``$ ssrun context set-current -n staging``

Step 4 - List all contexts

``$ ssrun context get ``

```
CURRENT    NAME                HOSTNAME/IP      PORT  API VERSION    SSL CA
*          staging  164.223.32.59     443  v1             false
           production          164.225.37.62     443  v1             true
```
note: the * in the "CURRENT" column of the staging entry shows it is the active context

Step 5 - Login on the staging instance

``$ ssrun login -u my_staging_user -p my_staging_user_password``

Step 6 - Save secret from staging Secrets Safe instance on your file system
``$ ssrun secret get path/to/staging:secret -f mysecret``

Step 7 - Switch contexts so your CLI is pointing at the production Secrets Safe instance

``$ ssrun context set-current -n production``

Step 8 - Log in with a user from the production Secrets Safe instance

``$ ssrun login -u my_production_user -p my_production_user_password``

Step 9 - Create a new secret on the production instance storing the value retrieved from the staging instance

``$ ssrun secret create path/to/production:secret -f mysecret``

That's it! You just interacted with multiple Secrets Safe instances from your CLI using contexts!

If you want to learn more about Secrets Safe CLI contexts you can use the -h flag

``$ ssrun context -h``

#### *Note on CLI Context and Environment Variables*

In addition, specific environment variables may override the current configured context:

```
$ export SECRETSSAFE_HOST=<IP address or hostname of Secrets Safe instance>
$ export SECRETSSAFE_PORT=<port of Secrets Safe instance>
$ export SECRETSSAFE_VERIFY_CA=<bool indicating if ca should be verified>
```

**Important**: If either of the above environment variables are defined they will override what is in the current context
