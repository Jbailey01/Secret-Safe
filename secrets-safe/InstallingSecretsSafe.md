Secrets Safe Installation <!-- omit in toc -->
============================

The Secrets Safe Kubernetes installation script will perform several kubectl commands to insert data into the cluster and will use helm (v3) to install the application. 


# Table Of Contents <!-- omit in toc -->

- [Prerequisites](#prerequisites)
- [Installation Instructions](#installation-instructions)
- [Upgrade Instructions](#upgrade-instructions)
- [Uninstall Instructions](#uninstall-instructions)
- [Additional Notes - Nginx Ingress Installation](#additional-notes---nginx-ingress-installation)

# Prerequisites
1. A set of hosts running Kubernetes version 1.14, 1.15, 1.16, 1.17, 1.18, 1.19, or 1.20 must be available to deploy Secrets Safe on. 
        * As a reference deployment Secrets Safe has been tested on a three node Kubernetes cluster each with a minimum of 7 GB of RAM
2. Kubectl installed and configured with full permissions to the cluster. The version of kubectl must be within one minor version of the cluster (above or below). 
        * See the following link for info on installing kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux 
3. Helm 3 installed
        * See the following link for info on installing helm: https://helm.sh/docs/intro/install/#from-script
4. In order for the application to be reachable an nginx ingress controller must be configured in the cluster.
5. The installing user must provide BeyondTrust their DockerHub username in advance in order for them to be given permission to pull the required images. 

# Installation Instructions

The install.sh script is a bash entrypoint which installs Secrets Safe through a series of `kubectl` calls and then a `helm install` call. Values in the file 'values.yml' within the helm chart will be used as defaults for the install. The install.sh script itself can be supplied with values either through arguments, through environment variables, or interactively. Values passed by argument will override any other form, then environment variables will be accepted, finally mandatory values not specified otherwise will be requested interactively. 

To see a list of accepted parameters run the install script with --help.

``
./install.sh --help 
``

The following is an example of installing Secret Safe using a postgreSQL database. 

``
./install.sh --namespace secrets-safe --docker-hub-username docker-user --docker-hub-password dockerpass --docker-hub-email docker-user@beyondtrust.com --database-type postgres --connection-string 'Server=secretssafe.database.beyondtrust.com;Database=secrets-safe;Port=5432;User Id=postgresql-user@secretssafe;Password=postgresql-password;Ssl Mode=Require;'
``

The following is an example of installing Secrets Safe using an Oracle database.

`` 
./install.sh --namespace secrets-safe --docker-hub-username docker-user --docker-hub-password dockerpass --docker-hub-email docker-user@beyondtrust.com --database-type oracle --connection-string 'User Id=oracleuser;Password=oraclepass;Data Source=10.10.10.10:1521/XE;' 
``
The following is an example of installing Secrets Safe using an Microsoft SQL Server database.

`` 
./install.sh --namespace secrets-safe --docker-hub-username docker-user --docker-hub-password dockerpass --docker-hub-email docker-user@beyondtrust.com --database-type mssql --connection-string 'Server=10.10.10.10;Database=secrets-safe;User Id=sqluser;Password=sqlpass;' 
``

Once the application is installed a means to access it is also required. Currently Secrets Safe is compatible the nginx ingress controller. 

# Upgrade Instructions

To upgrade an existing Secrets Safe installation from a cluster run the install script with the --upgrade parameter. This will preserve all custom values entered for the release. Additional value overrides may be specified during the upgrade either with additional parameters or by modifying the values file prior to upgrade and specifying the --values-from-file flag. 


   ``
   ./install.sh --upgrade
   ``

# Installing with a Certificate

Please see the accompanying Certificates.md file for instructions on how to mount a custom certificate in a Secrets Safe installation. 

# Uninstall Instructions

To remove a Secrets Safe installation from a cluster run the uninstall script. The uninstall script will remove all Secrets Safe data, containers, secrets, etc from the cluser. This does not include removing the database. 


   ``
   ./uninstall.sh
   ``
   
   If an installation did not complete successfully then it is recommended for the uninstaller to be run prior to the installer being run again. 
