#!/bin/bash

export KUBE_NAMESPACE=$1
export CERT_PASSWORDS=''

if [ "$#" -lt 2 ]; then
    echo "Usage:"
    echo "    ./create_all.sh <namespace> <use_v1_api>"
    exit 0
fi

./clean_certs.sh $KUBE_NAMESPACE

echo "Removing any pre-existing secret for this cert."
kubectl delete -n $KUBE_NAMESPACE secret rabbitmqclientcertsecret
if [ "$2" == "true" ]; then
    source ./create_cert.sh rabbitmqclient client $KUBE_NAMESPACE
else
    source ./create_cert_v1beta1.sh rabbitmqclient client $KUBE_NAMESPACE
fi
kubectl create -n $KUBE_NAMESPACE secret generic rabbitmqclientcertsecret --from-file=rabbitmqclient/keycert.p12
rm -rf rabbitmqclient

echo "Removing any pre-existing secret for this cert."
kubectl delete -n $KUBE_NAMESPACE secret rabbitmqcertsecret
if [ "$2" == "true" ]; then
    source ./create_cert.sh rabbitmq server $KUBE_NAMESPACE
else
    source ./create_cert_v1beta1.sh rabbitmq server $KUBE_NAMESPACE
fi
kubectl create -n $KUBE_NAMESPACE secret generic rabbitmqcertsecret --from-file=rabbitmq/cert.pem --from-file=rabbitmq/key.pem
rm -rf rabbitmq

for i in standardgateway healthmonitor keymanager authenticator authorizer lockbox auditor
do
    echo "Removing any pre-existing secret for this cert."
    rm -rf $i
    kubectl delete -n $KUBE_NAMESPACE secret ${i}certsecret
    if [ "$2" == "true" ]; then
        source ./create_cert.sh $i server $KUBE_NAMESPACE
    else
        source ./create_cert_v1beta1.sh $i server $KUBE_NAMESPACE
    fi
    kubectl create -n $KUBE_NAMESPACE secret generic ${i}certsecret --from-file=$i/keycert.p12
    rm -rf $i
done

# split string into an array for easier processing
IFS=',' read -r -a CERT_PASSWORD_ARRAY <<< "${CERT_PASSWORDS}"
cert_password_array_length="${#CERT_PASSWORD_ARRAY[@]}"
secret_data_string=''
for((i=0;i<$cert_password_array_length;i=$((i+2))))
do
    # format to be used in secret yaml <service>: <password> \n
    secret_data_string=$secret_data_string'  '${CERT_PASSWORD_ARRAY[i]}:' '${CERT_PASSWORD_ARRAY[$((i + 1))]}$'\n'
done

kubectl delete -n $KUBE_NAMESPACE secret certificate-passwords

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Secret
metadata:
  name: certificate-passwords
  namespace: $KUBE_NAMESPACE
type: Opaque
data:
$secret_data_string
EOF
