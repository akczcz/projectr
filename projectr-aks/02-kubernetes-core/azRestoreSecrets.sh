#!/bin/bash
VAULTNAME=kv-projectr-dev1
SUBSCRIPTIONID=00000000-0000-0000-0000-000000000000
SECRETS='
  SECRET1
  AKS-PERS-STORAGE-KEY
  APPLICATIONINSIGHTS-COMPUTE-CONNSTRING
  ELASTIC-HOST
  ELASTIC-PORT
  ELASTIC-USER
  MONGO-DBNAME
  MONGO-HOST
  MONGO-PASSWORD
  MONGO-USER
  REDIS-COMPUTE-CONNSTRING
  SERVICEBUS-UNIVERSAL-CONNSTRING
  SQL-CONNECTION-STRING
  SQL-DB-NAME
  SQL-HOST
  SQL-PASSWORD
  SQL-USERNAME
  '

for i in $SECRETS
do
    az keyvault secret restore --file $i --vault-name $VAULTNAME --subscription $SUBSCRIPTIONID
    echo $i
done