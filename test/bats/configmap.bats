#!/usr/bin/env bats

function setup {
  ../../keg my-config ../fixtures/env/core.env ../fixtures/env/prod.env
}

function teardown {
  rm -fr create-configmap-my-config.sh env-snippet-my-config.yaml
}

@test "generates create-configmap-my-config.sh" {
  run cat create-configmap-my-config.sh
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '#!/bin/sh' ]
  [ "${lines[1]}" = 'kubectl create configmap my-config --from-literal=name="Product Name" --from-literal=db-driver="com.mysql.jdbc.Driver" --from-literal=db-pool-minsize="10" --from-literal=db-pool-maxsize="20" --from-literal=db-url="jdbc:mysql://db.example.com/mydb?characterEncoding=UTF-8"' ]
}


@test "create-configmap-my-config.sh is executable" {
  run test -x create-configmap-my-config.sh
  [ "$status" -eq 0 ]
}

@test "generates env-snippet-my-config.yaml" {
  run cat env-snippet-my-config.yaml
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "env:" ]]
  [[ "${lines[21]}" =~ "- name: DB_URL" ]]
  [[ "${lines[22]}" =~ "valueFrom:" ]]
  [[ "${lines[23]}" =~ "configMapKeyRef:" ]]
  [[ "${lines[24]}" =~ "name: my-config" ]]
  [[ "${lines[25]}" =~ "key: db-url" ]]
}
