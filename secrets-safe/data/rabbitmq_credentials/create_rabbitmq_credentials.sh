#!/bin/bash

#
# This script creates random strings to enter into the kubernetes API as the rabbitmq credential secrets. 
# The first argument is the namespace. The second, third, and fourth arguments are optional overrides for the credentials.
# 

if [ "$#" -lt 1 ]; then
    echo "Usage:"
    echo "    ./create_rabbitmq_credentials.sh <namespace> [rabbitmq_user] [rabbitmq_pass] [erlang_cookie]"
    exit 0
fi

export KUBE_NAMESPACE=$1

if [ -z "$2" ]; then
    export RABBIT_USER=$(head -n 10 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1 | tr -d '\n' | base64)
else
    export RABBIT_USER=$(echo -n "$2" | base64)
fi

if [ -z "$3" ]; then
    export RABBIT_PASS=$(head -n 10 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1 | tr -d '\n'| base64)
else
    export RABBIT_PASS=$(echo -n "$3" | base64)
fi

if [ -z "$4" ]; then
    export ERLANG_COOKIE=$(head -n 10 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 | tr -d '\n'| base64)
else
    export ERLANG_COOKIE=$(echo -n "$4" | base64)
fi

kubectl delete -n $KUBE_NAMESPACE secret rabbitmqcredentials-secret > /dev/null 2>&1

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: rabbitmqcredentials-secret
  namespace: $KUBE_NAMESPACE
type: Opaque
data:
  rabbitmq-username: $RABBIT_USER
  rabbitmq-password: $RABBIT_PASS
  rabbitmq-erlang-cookie: $ERLANG_COOKIE
EOF
