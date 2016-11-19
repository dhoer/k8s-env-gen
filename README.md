# Kubernetes environment generator

Makes [docker env files](https://docs.docker.com/compose/env-file/) 
compatible with kubernetes by; generating a _create configmap_ command 
with kubernetes compatible keys, and generating a _environment snippet_ 
to paste into deployment yaml that links environment variables back to 
configmap. 

Reason for this:

1. Using create configmap with --from-file option nests data which can't be mapped to env deployment file
1. [Environment Variable names](https://google.github.io/styleguide/shell.xml?showone=Constants_and_Environment_Variable_Names#Constants_and_Environment_Variable_Names) are not allowed as root configmap keys

## Usage

Execute the following to generate both configmap command and environment snippet:

`k8s-env-gen.sh configmap-name my.env`

This will convert environment keys into kubernetes compatible format, 
generate create configmap command, and map keys back to original 
environment name in snippet.

### Example

```sh
$ k8s-env-gen.sh my-config my.env
```

```sh
kubectl create configmap my-config --from-literal=db-driver=com.mysql.jdbc.Driver --from-literal=db-pool-maxsize=15 --from-literal=db-pool-minsize=10
```

```yaml
        env:
          - name: DB_DRIVER
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-driver
          - name: DB_POOL_MAXSIZE
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-pool-maxsize
          - name: DB_POOL_MINSIZE
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-pool-minsize
```

#### Create configmap:

```sh
$ kubectl create configmap my-config --from-literal=db-driver=com.mysql.jdbc.Driver --from-literal=db-pool-maxsize=15 --from-literal=db-pool-minsize=10
```

#### Verify configmap:

```sh
$ kubectl get configmap my-conf -o yaml
```

```yaml
apiVersion: v1
data:
  db-driver: com.mysql.jdbc.Driver
  db-pool-maxsize: "15"
  db-pool-minsize: "10"
  db-user: my-app
kind: ConfigMap
metadata:
  creationTimestamp: 2016-11-19T00:01:18Z
  name: my-conf
  namespace: my-app
  resourceVersion: "9098351"
  selfLink: /api/v1/namespaces/my-app/configmaps/my-conf
  uid: 4bea0444-adeb-11e6-8c60-065eece225bf
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
          - name: DB_DRIVER
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-driver
          - name: DB_POOL_MAXSIZE
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-pool-maxsize
          - name: DB_POOL_MINSIZE
            valueFrom:
              configMapKeyRef:
                name: my-config
                key: db-pool-minsize
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: my-secret
                key: db-password
          - name: DB_USER
            valueFrom:
              secretKeyRef:
                name: my-secret
                key: db-user
          - name: DB_URL
            valueFrom:
              secretKeyRef:
                name: my-secret
                key: db-url
        ports:
        - containerPort: 8080
      - name: redirect-http-to-https
        image: hope/redirect-http-to-https
        imagePullPolicy: Always
        ports:
        - containerPort: 80
```
