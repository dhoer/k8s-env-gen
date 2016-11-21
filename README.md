# Kubernetes Environment Generator

Makes [docker env files](https://docs.docker.com/compose/env-file/) 
compatible with kubernetes by generating: 

1. _create configmap_ command with kubernetes compatible keys
1. _environment snippet_ to paste into deployment yaml that links environment variables back to configmap 

Reason for this (kubernetes v1.4):

* [Environment Variable names](https://google.github.io/styleguide/shell.xml?showone=Constants_and_Environment_Variable_Names#Constants_and_Environment_Variable_Names) are not allowed as root configmap keys
* Using create configmap with --from-file option nests data which can't be mapped to env deployment file

## Usage

Copy `keg` to `/usr/local/bin`. 

Execute the following to generate both configmap command and environment snippet:

`keg configmap-name env-file [env-file ...]`

Keys repeated in subsequent files will overwrite previous key values.

### Example

```sh
$ cat env/core.env 
NAME=Product Name
DB_DRIVER=com.mysql.jdbc.Driver
DB_POOL_MAXSIZE=15
DB_POOL_MINSIZE=10

$ cat env/prod.env 
DB_POOL_MAXSIZE=20
DB_URL=jdbc:mysql://db.example.com/mydb?characterEncoding=UTF-8

$ keg my-config env/core.env env/prod.env

kubectl create configmap my-config --from-literal=name="Product Name" --from-literal=db-driver="com.mysql.jdbc.Driver" --from-literal=db-pool-minsize="10" --from-literal=db-pool-maxsize="20" --from-literal=db-url="jdbc:mysql://db.example.com/mydb?characterEncoding=UTF-8"

        env:
          - name: NAME
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: name
          - name: DB_DRIVER
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-driver
          - name: DB_POOL_MINSIZE
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-pool-minsize
          - name: DB_POOL_MAXSIZE
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-pool-maxsize
          - name: DB_URL
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-url
```

#### Create configmap:

```sh
$ kubectl create configmap my-config --from-literal=name="Product Name" --from-literal=db-driver="com.mysql.jdbc.Driver" --from-literal=db-pool-minsize="10" --from-literal=db-pool-maxsize="20" --from-literal=db-url="jdbc:mysql://db.example.com/mydb?characterEncoding=UTF-8"
```

#### Verify configmap:

```sh
$ kubectl get configmap my-config -o yaml
```

```yaml
apiVersion: v1
data:
  db-driver: com.mysql.jdbc.Driver
  db-pool-maxsize: "20"
  db-pool-minsize: "10"
  db-url: jdbc:mysql://db.example.com/mydb?characterEncoding=UTF-8
  name: Product Name
kind: ConfigMap
metadata:
  creationTimestamp: 2016-11-20T01:59:33Z
  name: my-config
  namespace: my-app
  resourceVersion: "9281367"
  selfLink: /api/v1/namespaces/my-app/configmaps/my-config
  uid: fb9eedcb-aec4-11e6-8c60-065eece225bf
```

#### Paste snippet into deployment yaml

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  template:
    metadata:
      labels:
        run: my-app
        app: my-app
        env: production
    spec:
      containers:
      - name: my-app
        image: quay.io/example/my-app:LATEST
        imagePullPolicy: Always
        env:
          - name: NAME
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: name
          - name: DB_DRIVER
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-driver
          - name: DB_POOL_MINSIZE
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-pool-minsize
          - name: DB_POOL_MAXSIZE
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-pool-maxsize
          - name: DB_URL
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-url
          - name: DB_USER
            valueFrom:
              secretKeyRef:
                name: my-secret
                key: db-user
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: my-secret
                key: db-password
        ports:
        - containerPort: 8080
      - name: redirect-http-to-https
        image: hope/redirect-http-to-https
        imagePullPolicy: Always
        ports:
        - containerPort: 80
```
