#!/bin/bash

export KUBE_NAMESPACE=$1

if [ "$#" -lt 1 ]; then
    echo "Usage:"
    echo "    ./clean_certs.sh <namespace>"
    exit 0
fi

echo "Cleaning any certs or signing requests which already exist in namespace."

for i in txt .cer serial crt p12 pem ; do 
	rm -rf `find . -name "*${i}*"` ; 
done

for i in rabbitmqclient rabbitmq standardgateway healthmonitor keymanager authenticator authorizer lockbox auditor ; do
	kubectl delete csr $i.$KUBE_NAMESPACE-namespace ;
done
