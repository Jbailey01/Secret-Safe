#!/bin/bash

export KUBE_NAMESPACE=$3

if [ "$#" -lt 3 ]; then
    echo "Usage:"
    echo "    ./create_cert_v1beta1.sh <service_name> <server | client> <namespace>"
    exit 0
fi

echo "Creating cert for ${1} as a ${2}."

mkdir $1
cd $1
openssl genrsa -out key.pem 2048

if [ "$OS" = "Windows_NT" ]
then
	CERT_SUBJ="//CN=$1\O=$2"
else
	CERT_SUBJ="/CN=$1/O=$2"
fi

openssl req -new -config ../conf/openssl_v1beta1.cnf -key key.pem -out req.pem -outform PEM -subj "$CERT_SUBJ" -nodes -extensions $2_ca_extensions

kubectl delete csr $1.$KUBE_NAMESPACE-namespace

cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: $1.$KUBE_NAMESPACE-namespace
spec:
  groups:
  - system:authenticated
  request: $(cat req.pem | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - $2 auth
EOF

CERT_PASS=$(openssl rand -base64 32)
CERT_PASS_ENCODED=$( echo -n $CERT_PASS | base64)

# create comma separated string with the form <servicename>, <encoded_password>
if [ ! -z "$CERT_PASSWORDS" ]
then
	CERT_PASSWORDS=$CERT_PASSWORDS,
fi
CERT_PASSWORDS=$CERT_PASSWORDS$1,$CERT_PASS_ENCODED

RETRY_COUNTER=0

while [ $RETRY_COUNTER -lt 5 ]
do
	kubectl certificate approve $1.$KUBE_NAMESPACE-namespace

	kubectl get csr $1.$KUBE_NAMESPACE-namespace -o jsonpath='{.status.certificate}' | base64 --decode > cert.pem

	if [ ! -f cert.pem ] || [ ! -s cert.pem ]; then
    		echo "Cluster did not provide a valid certificate upon request, retrying..." >&2
		sleep 1
		((RETRY_COUNTER++))
	else
		break
	fi
done

# ensure cert pem file exists before trying to create certificate
if [ ! -f cert.pem ] || [ ! -s cert.pem ]; then
    echo "Cluster was unable to provide a certificate." >&2
	exit 1
fi

openssl pkcs12 -export -out keycert.p12 -in cert.pem -inkey key.pem -passout pass:$CERT_PASS
cd ..

