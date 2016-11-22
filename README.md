# Kubernetes Environment Generator

Makes [docker env files](https://docs.docker.com/compose/env-file/) 
compatible with kubernetes by generating: 

1. configmap script or secret yaml file with kubernetes compatible keys
1. environment snippet to paste into deployment yaml that links environment variables back to configmap or secret

Reason for this (kubernetes v1.3):

* [Environment Variable names](https://google.github.io/styleguide/shell.xml?showone=Constants_and_Environment_Variable_Names#Constants_and_Environment_Variable_Names) are not allowed as configmap or secret keys
* Using create configmap with --from-file option nests data which can't be mapped to env deployment file

## Usage

Copy `keg` to `/usr/local/bin`. 

Execute the following to generate configmap command or secret yaml file, and environment snippet:

`keg [-s] name file [file ...]`

Where:
  
- `-s` - Create secret yaml file and env snippet
- `name` - Configmap or secret name
- `file` - Path to environment file

Keys repeated in subsequent files will overwrite previous key values. 
Comments and blank spaces in env files are ignored.

WARNING! Double quotes and variable substitutions in env values are not supported at this time.

### ConfigMap Example

```
$ cat ./env/core.env 
# =Comments and empty lines are ignored
NAME=Product Name

DB_DRIVER=com.mysql.jdbc.Driver
DB_POOL_MAXSIZE=15
DB_POOL_MINSIZE=10
```

```
$ cat ./env/prod.env 
# =Comments and empty lines are ignored
DB_POOL_MAXSIZE=20

DB_URL=jdbc:mysql://db.example.com/mydb?characterEncoding=UTF-8
```

```sh
$ keg my-config ./env/core.env ./env/prod.env

kubectl create configmap my-config --from-literal=name="Product Name" --from-literal=db-driver="com.mysql.jdbc.Driver" --from-literal=db-pool-minsize="10" --from-literal=db-pool-maxsize="20" --from-literal=db-url="jdbc:mysql://db.example.com/mydb?characterEncoding=UTF-8"

Created create-configmap-my-config.sh

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

Created env-snippet-my-config.yaml
```

#### Create configmap

```sh
$ ./create-configmap-my-config.sh
configmap "my-config" created
```

#### Verify configmap

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
        ports:
        - containerPort: 8080
      - name: redirect-http-to-https
        image: hope/redirect-http-to-https
        imagePullPolicy: Always
        ports:
        - containerPort: 80
```

### Secret Example

```
$ cat ./env/secret-core.env
# For demo only, never commit secrets to git
DB_USER=admin
DB_PASSWORD=mysql
```

```
$ cat ./env/secret-prod.env
# For demo only, never commit secrets to git
DB_PASSWORD=4J,brw=v\G}dF4JC7QYVWjeHu;GRen
```

```sh
$ keg -s my-secret ./env/secret-core.env ./env/secret-prod.env

apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  db-user: YWRtaW4=
  db-password: NEosYnJ3PXZcR31kRjRKQzdRWVZXamVIdTtHUmVu

Created my-secret.yaml

        env:
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

Created env-snippet-my-secret.yaml
```

#### Create secret

```sh
$ kubectl create -f ./my-secret.yaml
secret "my-secret" created
```

#### Verify secret

```sh
$ kubectl get secret my-secret -o yaml
```

```yaml
apiVersion: v1
data:
  db-password: NEosYnJ3PXZcR31kRjRKQzdRWVZXamVIdTtHUmVu
  db-user: YWRtaW4=
kind: Secret
metadata:
  creationTimestamp: 2016-11-21T21:50:26Z
  name: my-secret
  namespace: my-app
  resourceVersion: "9590345"
  selfLink: /api/v1/namespaces/my-app/secrets/my-secret
  uid: 82c785fb-b034-11e6-8c60-065eece225bf
type: Opaque
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
