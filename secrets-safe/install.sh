#!/bin/bash

#
# Collects sensitive deployment information and installs Secrets Safe on the cluster kubectl is configured for.
# Arguments may be provided through parameters, interactively, or as environment variables. 
#

WORKING_DIR=`dirname $(readlink -f "${0}")`
if [ -d ${WORKING_DIR}/current_install ]; then
    rm -rf ${WORKING_DIR}/current_install
fi
mkdir ${WORKING_DIR}/current_install

source ${WORKING_DIR}/data/internal_scripts/check_version.sh

#####################
# Collect Variables #
#####################

# The default kubernetes namesapce if not specified
export DEFAULT_KUBE_NAMESPACE="secrets-safe"

# The release name for installations in the default namespace
export SECRET_SAFE_RELEASE="secrets-safe-release"

# Only offer help when requested
export PRINT_HELP=false

# Gather commandline args provided by the user and export them to environment variables. 
export ARGUMENTS=""
while (( "$#" )); do
    case "$1" in
        --services-tag)
          export SERVICES_TAG=${2}
          export ARGUMENTS="$ARGUMENTS ${1}"
          shift 2
          ;;
        --docker-hub-username)
          export DOCKER_HUB_USERNAME=${2}
          export ARGUMENTS="$ARGUMENTS ${1}"
          shift 2
          ;;
        --docker-hub-password)
          export DOCKER_HUB_PASSWORD=${2}
          export ARGUMENTS="$ARGUMENTS ${1}"
          shift 2
          ;;
        --docker-hub-email)
          export DOCKER_HUB_EMAIL=${2}
          export ARGUMENTS="$ARGUMENTS ${1}"
          shift 2
          ;;
        --database-type)
          export DATABASE_TYPE="${2}"
          export ARGUMENTS="$ARGUMENTS ${1}"
          shift 2
          ;;
        --connection-string)
          export CONNECTION_STRING="${2}"
          export ARGUMENTS="$ARGUMENTS ${1}"
          shift 2
          ;;
        --namespace)
          export KUBE_NAMESPACE="${2}"
          export ARGUMENTS="$ARGUMENTS ${1}"
          shift 2
          ;;
        --ingress-hostname)
          export INGRESS_HOST="${2}"
          export ARGUMENTS="$ARGUMENTS ${1}"
          shift 2
          ;;
        --ingress-cert-secret-name)
          export CERT_SECRET_NAME="${2}"
          export ARGUMENTS="$ARGUMENTS ${1}"
          shift 2
          ;;
        --enable-ingress)
          export ENABLE_INGRESS="${2}"
          export ARGUMENTS="$ARGUMENTS ${1}"
          shift 2
          ;;
        --docker-hub-update-creds)
          export UPDATE_DOCKER_HUB_CREDENTIALS=true
          shift
          ;;
        --upgrade)
          export UPGRADE_EXISTING_INSTALL=true
          shift
          ;;
        --values-from-file)
          export VALUES_FROM_FILE=true
          shift
          ;;
        --connection-string-update)
          export UPDATE_CONNECTION_STRING=true
          shift
          ;;
        --rotate-certificates)
          export ROTATE_CERTIFICATES=true
          shift
          ;;
        --help)
          export PRINT_HELP=true
          shift
          ;;
        -h)
          export PRINT_HELP=true
          shift
          ;;
        *) # unknown keyword args are not supported
          echo "Error: Unsupported arg ${1}" >&2
          exit 1
          ;;
    esac
done

# Print help if requested
if ${PRINT_HELP}; then

    echo 'Accepted keyword args for the (default) install function:'
    echo '--docker-hub-username ${DOCKER_HUB_USERNAME}                >>> sets the Docker Hub username used to pull required Docker images'
    echo '--docker-hub-password ${DOCKER_HUB_PASSWORD}                >>> sets the Docker Hub users password'
    echo '--docker-hub-email ${DOCKER_HUB_EMAIL}                      >>> sets the Docker Hub email associated with the user'
    echo '--services-tag ${SERVICES_TAG}                              >>> sets the images tag to use (defaults to values file value)'
    echo '--database-type ${DATABASE_TYPE}                            >>> sets the type of database to connect to (accepts postgres, oracledb or sqlserver)'
    echo '--connection-string ${CONNECTION_STRING}                    >>> sets the database connection string'
    echo '--namespace ${KUBE_NAMESPACE}                               >>> sets the kubernetes namespace to install into'
    echo '--ingress-hostname ${INGRESS_HOST}                          >>> sets a specific hostname by which the application may be reached (defaults to values file value)'
    echo '--ingress-cert-secret-name ${CERT_SECRET_NAME}              >>> sets the name of the TLS ingress secret - requires a specific ingress hostname if set'
    echo '--enable-ingress ${ENABLE_INGRESS}                          >>> sets whether the kubernetes ingress will be enabled (defaults to values file value)'
    echo ''
    echo 'All arguments are optional, however, the user will be prompted for the mandatory values if not handed as arguments or exported as environment variables.'
    echo ''
    echo ''
    echo ''
    echo 'Required keyword args for the upgrade function:'
    echo '--upgrade                                                   >>> upgrades an existing instance to a new version, preserving the helm values currently in the release'
    echo 'Optional keyword args for the upgrade function:'
    echo '--services-tag ${SERVICES_TAG}                              >>> sets the images tag to use (defaults to values file value)'
    echo '--namespace ${KUBE_NAMESPACE}                               >>> sets the kubernetes namespace to install into, prompts if not specified'
    echo '--ingress-hostname ${INGRESS_HOST}                          >>> sets a specific hostname by which the application may be reached (defaults to values file value)'
    echo '--ingress-cert-secret-name ${CERT_SECRET_NAME}              >>> sets the name of the TLS ingress secret - requires a specific ingress hostname if set'
    echo '--enable-ingress ${ENABLE_INGRESS}                          >>> sets whether the kubernetes ingress will be enabled (defaults to values file value)'
    echo '--values-from-file                                          >>> overwrites values for the release with those values specified in the values file and the install call'
    echo ''
    echo ''
    echo ''
    echo 'Required keyword args for the dockerhub credentials update function:'
    echo '--docker-hub-update-creds                                   >>> sets the Docker Hub credentials to new values for an already installed instance'
    echo '--docker-hub-username ${DOCKER_HUB_USERNAME}                >>> sets the Docker Hub username used to pull required Docker images'
    echo '--docker-hub-password ${DOCKER_HUB_PASSWORD}                >>> sets the Docker Hub users password'
    echo '--docker-hub-email ${DOCKER_HUB_EMAIL}                      >>> sets the Docker Hub email associated with the user'
    echo 'Optional keyword args for the dockerhub credentials update function:'
    echo '--namespace ${KUBE_NAMESPACE}                               >>> sets the kubernetes namespace to install into, defaults to secrets-safe'
    echo ''
    echo ''
    echo ''
    echo 'Required keyword args for the connection string update function:'
    echo '--connection-string-update                                  >>> sets the connection string for an existing instance. This will seal an unsealed instance.'
    echo '--database-type ${DATABASE_TYPE}                            >>> sets the type of database to connect to (accepts postgres, oracledb or sqlserver)'
    echo '--connection-string ${CONNECTION_STRING}                    >>> sets the database connection string'
    echo 'Optional keyword args for the connection string update function:'
    echo '--namespace ${KUBE_NAMESPACE}                               >>> sets the kubernetes namespace to install into, defaults to secrets-safe'
    echo ''
    echo ''
    echo ''
    echo 'Required keyword args for the certificate rotation function:'
    echo '--rotate-certificates                                       >>> discards existing certificates and creates new ones'
    echo 'Optional keyword args for the certificate rotation function:'
    echo '--namespace ${KUBE_NAMESPACE}                               >>> sets the kubernetes namespace to install into, defaults to secrets-safe'
    echo ''
    echo ''
    echo 'Accepted keyword args for the help function:'
    echo '--help                                                      >>> brings up this menu -- all other arguments will be ignored.'
    echo ''
    exit 0
fi

# If a secondary function was called validate arguments then execute. 
if [ ${UPDATE_DOCKER_HUB_CREDENTIALS} ]; then 
    export SELECTED_FUNCTION="--docker-hub-update-creds"
    export ALLOWED_ARGUMENTS="--docker-hub-username --docker-hub-password --docker-hub-email --namespace" 
    export REQUIRED_ARGUMENTS="--docker-hub-username --docker-hub-password --docker-hub-email" 
    ${WORKING_DIR}/data/internal_scripts/validate_arguments.sh 
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    if [ -z "${KUBE_NAMESPACE}" ]; then
        export KUBE_NAMESPACE="${DEFAULT_KUBE_NAMESPACE}"
    fi
    if [ -z "${IMAGE_REGISTRY_LOCATION}" ]; then
        export IMAGE_REGISTRY_LOCATION=https://index.docker.io/v1/
    fi
    # Create the registry credentials secret, deleting any pre-existing instance
    kubectl delete -n $KUBE_NAMESPACE secret btregistryaccess > /dev/null 2>&1
    kubectl create -n $KUBE_NAMESPACE secret docker-registry btregistryaccess \
        --docker-server=${IMAGE_REGISTRY_LOCATION} \
        --docker-username=${DOCKER_HUB_USERNAME} \
        --docker-password=${DOCKER_HUB_PASSWORD} \
        --docker-email=${DOCKER_HUB_EMAIL}
    exit 0

elif [ ${UPDATE_CONNECTION_STRING} ]; then 
    export SELECTED_FUNCTION="--connection-string-update"
    export ALLOWED_ARGUMENTS="--database-type --connection-string --namespace" 
    export REQUIRED_ARGUMENTS="--database-type --connection-string" 
    ${WORKING_DIR}/data/internal_scripts/validate_arguments.sh 
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    if [ -z "${KUBE_NAMESPACE}" ]; then
        export KUBE_NAMESPACE="${DEFAULT_KUBE_NAMESPACE}"
    fi
    ${WORKING_DIR}/data/connection_strings/create_connection_strings_secret.sh "${DATABASE_TYPE}" "${CONNECTION_STRING}" "${KUBE_NAMESPACE}"
    exit 0

elif [ ${ROTATE_CERTIFICATES} ]; then 
    export SELECTED_FUNCTION="--rotate-certificates"
    export ALLOWED_ARGUMENTS="--namespace" 
    export REQUIRED_ARGUMENTS="" 
    ${WORKING_DIR}/data/internal_scripts/validate_arguments.sh 
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    if [ -z "${KUBE_NAMESPACE}" ]; then
        export KUBE_NAMESPACE="${DEFAULT_KUBE_NAMESPACE}"
    fi
    ${WORKING_DIR}/data/internal_scripts/rotate_service_certificates.sh ${KUBE_NAMESPACE}
    exit 0

elif [ ${UPGRADE_EXISTING_INSTALL} ]; then 
    export SELECTED_FUNCTION="--upgrade"
    export ALLOWED_ARGUMENTS="--services-tag --namespace --ingress-hostname --ingress-cert-secret-name --enable-ingress --values-from-file" 
    export REQUIRED_ARGUMENTS="" 
    ${WORKING_DIR}/data/internal_scripts/validate_arguments.sh 
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
fi

# User may set the kubernetes namespace, it will take on the default value if not specified. 
if [ -z "${KUBE_NAMESPACE}" ]; then
    echo -e "\nEnter the kubernetes namespace (enter to default to 'secrets-safe'): "
    read KUBE_NAMESPACE
    export KUBE_NAMESPACE
fi
if [ -z "${KUBE_NAMESPACE}" ]; then
    export KUBE_NAMESPACE="${DEFAULT_KUBE_NAMESPACE}"
fi

# Create the namespace if it does not exist and we are installing
kubectl get ns ${KUBE_NAMESPACE} > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    if [ "${UPGRADE_EXISTING_INSTALL}" == "true" ]; then
        echo -e "\n\n\nThe ${KUBE_NAMESPACE} kubernetes namespace does not yet exist. \nNo existing install found to upgrade. Exiting.\n\n"
        exit 1
    fi
    echo -e "\n\n\nThe ${KUBE_NAMESPACE} kubernetes namespace does not yet exist. Creating.\n\n"
    kubectl create ns ${KUBE_NAMESPACE}
else
    echo -e "\n\n\nInstalling secrets-safe into the ${KUBE_NAMESPACE} namespace.\n\n"
    sleep 1
fi

# Adjust the release name if installing to a non-default namespace
if [ "${KUBE_NAMESPACE}" != "${DEFAULT_KUBE_NAMESPACE}" ]; then
    SECRET_SAFE_RELEASE="secrets-safe-${KUBE_NAMESPACE}-release"
    if [ "${UPGRADE_EXISTING_INSTALL}" == "true" ]; then
        echo -e "\n\n\nUpgrading secrets-safe with release name ${SECRET_SAFE_RELEASE}.\n\n"
    else
        echo -e "\n\n\nInstalling secrets-safe with release name ${SECRET_SAFE_RELEASE}.\n\n"
    fi
    sleep 1
fi

# exit early if helm3 is not installed
helm3 version | grep v3 &> /dev/null
if [[ $? != 0 ]]; then
    echo -e "\n\n\nHelm3 is required but not installed. Exiting.\n\n"
    exit 1
fi

export SECRETS_SAFE_INSTALLED=`helm list --namespace ${KUBE_NAMESPACE} | grep ${SECRET_SAFE_RELEASE} | wc -l`

# Exit if we are trying a new install and an instance already exists
if [ "${SECRETS_SAFE_INSTALLED}" == "1" ] && [ "${UPGRADE_EXISTING_INSTALL}" != "true" ]; then
    echo "Unable to install secrets-safe as it is already installed. Please run uninstall.sh first."
    exit 1
fi
# Exit if we are trying an upgrade and an instance does not exists
if [ "${SECRETS_SAFE_INSTALLED}" != "1" ] && [ "${UPGRADE_EXISTING_INSTALL}" == "true" ]; then
    echo "Unable to upgrade secrets-safe as it is not installed in this namespace."
    exit 1
fi

# we are doing a upgrade but downgrades in version are not explicitly enabled
if [ "${UPGRADE_EXISTING_INSTALL}" == "true" ] && [ "${SECRETS_SAFE_ALLOW_DOWNGRADE}" != "true" ] ; then
    CURRENT_VERSION=$(helm get values -n ${KUBE_NAMESPACE} ${SECRET_SAFE_RELEASE} -a | grep imageTag | cut -d ' ' -f2)
    # if this is a downgrade prompt for confirmation
    if is_version_downgrade $CURRENT_VERSION $SERVICES_TAG ; then
        while true; do
            read -p "You are updating from $CURRENT_VERSION to $SERVICES_TAG, continue? " yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) exit 0;;
                * ) echo "Please enter y or n.";;
            esac
        done        
    fi
fi

# If we are upgrading take the existing values from the cluster
if [ "${UPGRADE_EXISTING_INSTALL}" == "true" ] && [ "${VALUES_FROM_FILE}" != "true" ]; then
    export OLD_CERT_SECRET_NAME=`helm get values -n ${KUBE_NAMESPACE} secrets-safe-release | grep certificateSecretName | cut -d ' ' -f2 | sed 's/"//g'`
    export OLD_INGRESS_ENABLED=`helm get values -n ${KUBE_NAMESPACE} secrets-safe-release | grep enabled | cut -d ':' -f2 | sed 's/ //g'`
    export OLD_INGRESS_HOST=`helm get values -n ${KUBE_NAMESPACE} secrets-safe-release | grep host | cut -d ':' -f2 | sed 's/ //g'` 
    export OLD_IMAGE_REGISTRY_NAME=`helm get values -n ${KUBE_NAMESPACE} secrets-safe-release | grep registryName | cut -d ' ' -f2`
    export REPLICAS_OVERRIDE=`helm get values -a -n ${KUBE_NAMESPACE} secrets-safe-release | grep numberOfReplicas | cut -d ' ' -f2`

    if [ -z "${CERT_SECRET_NAME}" ]; then
        export CERT_SECRET_NAME="${OLD_CERT_SECRET_NAME}"
    fi
    if [ -z "${INGRESS_ENABLED}" ]; then
        export INGRESS_ENABLED="${OLD_INGRESS_ENABLED}"
    fi
    if [ -z "${INGRESS_HOST}" ]; then
        export INGRESS_HOST="${OLD_INGRESS_HOST}"
    fi
    if [ -z "${IMAGE_REGISTRY_NAME}" ]; then
        export IMAGE_REGISTRY_NAME="${OLD_IMAGE_REGISTRY_NAME}"
    fi
fi

# User may override the docker io URL with an environment variable, option not available on commandline. 
if [ -z "${IMAGE_REGISTRY_LOCATION}" ]; then
    export IMAGE_REGISTRY_LOCATION=https://index.docker.io/v1/
fi

# User will be prompted for a mandatory value for ingress hostname if they have defined a cert secret
if [ -n "${CERT_SECRET_NAME}" ]; then
    while [ -z "${INGRESS_HOST}" ]; do
        echo -e "\nEnter the Ingress Hostname (mandatory when a cert secret is specified): "
        read INGRESS_HOST
        export INGRESS_HOST
    done
fi
# User will be prompted for a value for Docker Hub username if not yet specified
while [ -z "${DOCKER_HUB_USERNAME}" ] && [ "${UPGRADE_EXISTING_INSTALL}" != "true" ]; do
    echo -e "\nEnter the Docker hub username (mandatory): "
    read DOCKER_HUB_USERNAME
    export DOCKER_HUB_USERNAME
done

# User will be prompted for a value for Docker Hub password if not yet specified
while [ -z "${DOCKER_HUB_PASSWORD}" ] && [ "${UPGRADE_EXISTING_INSTALL}" != "true" ]; do
    echo -e "\nEnter the Docker Hub password (mandatory - will be stored in a kubernetes secret, will not be echoed):"
    read -s DOCKER_HUB_PASSWORD
    export DOCKER_HUB_PASSWORD
done

# User will be prompted for a value for Docker Hub email if not yet specified
while [ -z "${DOCKER_HUB_EMAIL}" ] && [ "${UPGRADE_EXISTING_INSTALL}" != "true" ]; do
    echo -e "\nEnter the email associated with the Docker Hub username (mandatory): "
    read DOCKER_HUB_EMAIL
    export DOCKER_HUB_EMAIL
done

# User will be prompted for a value for database type if not yet specified
while [ "${DATABASE_TYPE}" != "postgres" ] && [ "${DATABASE_TYPE}" != "oracledb" ] && [ "${DATABASE_TYPE}" != "sqlserver" ] && [ "${UPGRADE_EXISTING_INSTALL}" != "true" ]; do
    echo -e "\nEnter the type of database you will connect this application to (mandatory - 'oracledb', 'postgres' or 'sqlserver'): "
    read DATABASE_TYPE
    export DATABASE_TYPE
done

# Collect the details for the database

while [ -z "${CONNECTION_STRING}" ] && [ "${UPGRADE_EXISTING_INSTALL}" != "true" ]; do
    echo -e "\nProvide ${DATABASE_TYPE} Connection String (mandatory - will be stored in a kubernetes secret, will not be echoed): "
    read -s CONNECTION_STRING
    export CONNECTION_STRING
done

#################################
# Store Current Values Override #
#################################

# Store overridden helm values in an overrides yaml file
echo -n "" > ${WORKING_DIR}/current_install/value_overrides.yaml

if [ -n "${IMAGE_REGISTRY_NAME}" ]; then
    echo "registryName: ${IMAGE_REGISTRY_NAME}" >> ${WORKING_DIR}/current_install/value_overrides.yaml
fi

if [ -n "${SERVICES_TAG}" ]; then
    echo "imageTag: ${SERVICES_TAG}" >> ${WORKING_DIR}/current_install/value_overrides.yaml
fi

if [ -n "${ENABLE_INGRESS}" ] || [ -n "${INGRESS_HOST}" ] || [ -n "${CERT_SECRET_NAME}" ]; then 
    echo "ingress:" >> ${WORKING_DIR}/current_install/value_overrides.yaml
    if [ -n "${ENABLE_INGRESS}" ]; then
        echo "  enabled: ${ENABLE_INGRESS}" >> ${WORKING_DIR}/current_install/value_overrides.yaml
    fi
    if [ -n "${INGRESS_HOST}" ]; then
        echo "  host: ${INGRESS_HOST}" >> ${WORKING_DIR}/current_install/value_overrides.yaml
    fi
    if [ -n "${CERT_SECRET_NAME}" ]; then
        echo "  certificateSecretName: ${CERT_SECRET_NAME}" >> ${WORKING_DIR}/current_install/value_overrides.yaml
    fi
fi

if [ -n "${REPLICAS_OVERRIDE}" ]; then
    echo "numberOfReplicas: ${REPLICAS_OVERRIDE}" >> ${WORKING_DIR}/current_install/value_overrides.yaml
fi

###################
# Prepare Cluster #
###################

# Create certificate secrets
export V1_CERTS_PRESENT="false"; 
for ver in `kubectl api-versions`; do 
    if [ "$ver" == "certificates.k8s.io/v1" ]; then 
        export V1_CERTS_PRESENT="true"; 
    fi 
done
echo "Creating certificates for services."
cd ${WORKING_DIR}/data/certs 
./create_all.sh $KUBE_NAMESPACE $V1_CERTS_PRESENT &> /dev/null

# Ensure our certificate creation was successful before moving on
if [[ $? -ne 0 ]]; then
    echo -e "\nThe kubernetes cluster was unable to generate a signed certificate. Please try again."
    exit 1
fi

if [ "${UPGRADE_EXISTING_INSTALL}" != "true" ]; then

    # Create the registry credentials secret, deleting any pre-existing instance
    kubectl delete -n $KUBE_NAMESPACE secret btregistryaccess > /dev/null 2>&1

    kubectl create -n $KUBE_NAMESPACE secret docker-registry btregistryaccess \
        --docker-server=${IMAGE_REGISTRY_LOCATION} \
        --docker-username=${DOCKER_HUB_USERNAME} \
        --docker-password=${DOCKER_HUB_PASSWORD} \
        --docker-email=${DOCKER_HUB_EMAIL}

    unset DOCKER_HUB_PASSWORD

    # Create the connection strings secret for the selected database type
    cd ${WORKING_DIR}/data/connection_strings
    ./create_connection_strings_secret.sh "${DATABASE_TYPE}" "${CONNECTION_STRING}" "${KUBE_NAMESPACE}"
    cd -

    unset CONNECTION_STRING
fi

# Check if rabbitmq credentials are absent so we can create them (This will occur during new installs and upgrades from instances where they are absent)
kubectl get secret -n ${KUBE_NAMESPACE} rabbitmqcredentials-secret > /dev/null 2>&1
if [[ $? -ne 0 ]]; then

    # Generate random strings for rabbitmq credentials
    cd ${WORKING_DIR}/data/rabbitmq_credentials
    ./create_rabbitmq_credentials.sh "${KUBE_NAMESPACE}"
    cd -
fi

# Ensure any instances running with old credentials are removed immediately
for j in `kubectl get -n $KUBE_NAMESPACE pods -l app=rabbitmq --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'` ; do
    kubectl delete -n $KUBE_NAMESPACE pod $j &
done

##################################
# Install or Upgrade Application # 
##################################


if [ "${UPGRADE_EXISTING_INSTALL}" == "true" ] ; then
    echo "Calling: helm upgrade ${SECRET_SAFE_RELEASE} --namespace ${KUBE_NAMESPACE} ${WORKING_DIR}/helm_chart/secrets-safe -f ${WORKING_DIR}/current_install/value_overrides.yaml"
    helm upgrade ${SECRET_SAFE_RELEASE} --namespace ${KUBE_NAMESPACE} ${WORKING_DIR}/helm_chart/secrets-safe -f ${WORKING_DIR}/current_install/value_overrides.yaml
else 
    echo "Calling: helm install ${SECRET_SAFE_RELEASE} --namespace ${KUBE_NAMESPACE} ${WORKING_DIR}/helm_chart/secrets-safe -f ${WORKING_DIR}/current_install/value_overrides.yaml"
    helm install ${SECRET_SAFE_RELEASE} --namespace ${KUBE_NAMESPACE} ${WORKING_DIR}/helm_chart/secrets-safe -f ${WORKING_DIR}/current_install/value_overrides.yaml
fi

echo -e "\nSelected helm values for the current install have been stored in ${WORKING_DIR}/current_install/value_overrides.yaml."
