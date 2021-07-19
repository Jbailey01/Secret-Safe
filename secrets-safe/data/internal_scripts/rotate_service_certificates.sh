#!/bin/bash

#
# This script rotates the certificates for the internal services, deleting the ones which currently exist. 
# It may be called with no arguments. 
#

export KUBE_NAMESPACE=$1

if [ "$#" -lt 1 ]; then
    echo "Usage:"
    echo "    ./rotate_service_certificates.sh <namespace>"
    exit 0
fi

WORKING_DIR=`dirname $(readlink -f "${0}")`

# Create certificate secrets
echo "Creating certificates for services."
cd ${WORKING_DIR}/../certs 
./create_all.sh $KUBE_NAMESPACE &> /dev/null

# Ensure our certificate creation was successful before moving on
if [[ $? -ne 0 ]]; then
    echo -e "\nThe kubernetes cluster was unable to generate a signed certificate. Please try again."
    exit 1
fi
