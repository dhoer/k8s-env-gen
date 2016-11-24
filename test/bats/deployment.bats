#!/usr/bin/env bats

function setup {
  ../../keg my-config ../fixtures/env/core.env ../fixtures/env/prod.env
  ../../keg -s my-secret ../fixtures/secret/core.env ../fixtures/secret/prod.env
  ruby -e "require 'yaml'; \
    configmap = YAML.load_file('env-snippet-my-config.yaml'); \
    secret = YAML.load_file('env-snippet-my-secret.yaml'); \
    snippet = configmap['env'].concat(secret['env']); \
    deployment = YAML.load_file('../fixtures/k8s/deployment.yaml'); \
    deployment['spec']['template']['spec']['containers'][0]['env'].replace(snippet); \
    IO.write('deployment.yaml', deployment.to_yaml);"
}

function teardown {
  rm -fr create-configmap-my-config.sh env-snippet-my-config.yaml
  rm -fr my-secret.yaml env-snippet-my-secret.yaml
  rm -fr deployment.yaml
}

@test "generates deployment.yaml with my-config and my-secret envs merged" {
  run cat deployment.yaml
  [ "$status" -eq 0 ]
  [[ "${lines[18]}" =~ "env:" ]]
  [[ "${lines[39]}" =~ "- name: DB_URL" ]]
  [[ "${lines[40]}" =~ "valueFrom:" ]]
  [[ "${lines[41]}" =~ "configMapKeyRef:" ]]
  [[ "${lines[42]}" =~ "name: my-config" ]]
  [[ "${lines[43]}" =~ "key: db-url" ]]
  [[ "${lines[49]}" =~ "- name: DB_PASSWORD" ]]
  [[ "${lines[50]}" =~ "valueFrom:" ]]
  [[ "${lines[51]}" =~ "secretKeyRef:" ]]
  [[ "${lines[52]}" =~ "name: my-secret" ]]
  [[ "${lines[53]}" =~ "key: db-password" ]]
}
