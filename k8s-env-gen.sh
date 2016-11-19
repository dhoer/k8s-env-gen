#!/bin/bash
# USAGE: ./k8s-env-gen.sh configmap-name my.env

# generates a configmap command
echo ""
echo -n "kubectl create configmap $1"
while IFS='' read -r line || [[ -n "$line" ]]; do
    if [[ $line == *"="* ]]
    then
        IFS='=' read -a kv <<< "$line"
        echo -n " --from-literal="
        echo -n "${kv[0]//_/-}" | tr '[:upper:]' '[:lower:]'
        echo -n "=${kv[1]}"
    fi
done < "$2"
echo ""
echo ""

# generates environment snippet to paste into deployment yaml
echo "        env:"
while IFS='' read -r line || [[ -n "$line" ]]; do
    if [[ $line == *"="* ]]
    then
        IFS='=' read -a kv <<< "$line"
        echo "          - name: ${kv[0]}"
        echo "            valueFrom:"
        echo "              configMapKeyRef:"
        echo "                name: $1"
        echo "                key: ${kv[0]//_/-}" | tr '[:upper:]' '[:lower:]'
    fi
done < "$2"
echo ""
