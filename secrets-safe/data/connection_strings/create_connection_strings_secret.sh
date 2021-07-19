#!/bin/bash

#
# This script creates connection strings for the secrets-safe microservices. 
# The first argument is the active type of DB, the second is the connection string, the thirdi s the namespace.
# 
# Args : Database Type, Connection String, Namespace
#

if [ "$#" -lt 3 ]; then
    echo "Usage:"
    echo "    ./create_connection_strings_secret.sh <db_type> <connection_string> <namespace>"
    exit 0
fi

export DB_TYPE=${1}

if [ "${DB_TYPE}" == "postgres" ]; then
    export ORACLE_CONNECTION_STRING="dummy"
    export PG_CONNECTION_STRING=${2}
    export SQLSERVER_CONNECTION_STRING="dummy"
elif [ "${DB_TYPE}" == "oracledb" ]; then
    export PG_CONNECTION_STRING="dummy"
    export ORACLE_CONNECTION_STRING=${2}
    export SQLSERVER_CONNECTION_STRING="dummy"
elif [ "${DB_TYPE}" == "sqlserver" ]; then
    export PG_CONNECTION_STRING="dummy"
    export ORACLE_CONNECTION_STRING="dummy"
    export SQLSERVER_CONNECTION_STRING=${2}
fi

export KUBE_NAMESPACE=${3}


# generate secrets-safe connection strings secret
kubectl delete -n $KUBE_NAMESPACE secret secrets-safe-connection-strings > /dev/null 2>&1
kubectl create -n $KUBE_NAMESPACE secret generic secrets-safe-connection-strings

ENCODED_DB_TYPE=$( echo -n $DB_TYPE | base64 -w 0)
kubectl patch -n $KUBE_NAMESPACE secret secrets-safe-connection-strings -p='{"data":{"'"database-type"'":"'"${ENCODED_DB_TYPE}"'"}}'

ENCODED_CONNECTION_STRING=$( echo -n $PG_CONNECTION_STRING | base64 -w 0)
kubectl patch -n $KUBE_NAMESPACE secret secrets-safe-connection-strings -p='{"data":{"'"postgres-connection-string"'":"'"${ENCODED_CONNECTION_STRING}"'"}}'

ENCODED_CONNECTION_STRING=$( echo -n $ORACLE_CONNECTION_STRING | base64 -w 0)
kubectl patch -n $KUBE_NAMESPACE secret secrets-safe-connection-strings -p='{"data":{"'"oracledb-connection-string"'":"'"${ENCODED_CONNECTION_STRING}"'"}}'

ENCODED_CONNECTION_STRING=$( echo -n $SQLSERVER_CONNECTION_STRING | base64 -w 0)
kubectl patch -n $KUBE_NAMESPACE secret secrets-safe-connection-strings -p='{"data":{"'"sqlserver-connection-string"'":"'"${ENCODED_CONNECTION_STRING}"'"}}'


for i in lockbox keymanager authorizer authenticator ; do
    for j in `kubectl get -n $KUBE_NAMESPACE pods -l run=$i --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'` ; do
        kubectl delete -n $KUBE_NAMESPACE pod $j &
    done
done
