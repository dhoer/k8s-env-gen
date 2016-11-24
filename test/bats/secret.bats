#!/usr/bin/env bats

function setup {
  ../../keg -s my-secret ../fixtures/secret/core.env ../fixtures/secret/prod.env
}

function teardown {
  rm -fr my-secret.yaml env-snippet-my-secret.yaml
}

@test "generates my-secret.yaml" {
  run cat my-secret.yaml
  [ "$status" -eq 0 ]
  [[ "${lines[3]}" =~ "name: my-secret" ]]
  [[ "${lines[6]}" =~ "db-user: YWRtaW4=" ]]
  [[ "${lines[7]}" =~ "db-password: NEosYnJ3PXZcR31kRjRKQzdRWVZXamVIdTtHUmVu" ]]
}

@test "generates env-snippet-my-secret.yaml" {
  run cat env-snippet-my-secret.yaml
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "env:" ]]
  [[ "${lines[6]}" =~ "- name: DB_PASSWORD" ]]
  [[ "${lines[7]}" =~ "valueFrom:" ]]
  [[ "${lines[8]}" =~ "secretKeyRef:" ]]
  [[ "${lines[9]}" =~ "name: my-secret" ]]
  [[ "${lines[10]}" =~ "key: db-password" ]]
}
