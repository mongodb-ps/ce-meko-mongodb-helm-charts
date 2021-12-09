# k8s_rs

**This documentation is a WIP**

## Table of Contents

- [k8s_rs](#k8s_rs)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Steps to Deploy](#steps-to-deploy)
  - [Prerequisites](#prerequisites)
  - [Deployment Requirements](#deployment-requirements)
    - [Ops Manager API Access Token _REQUIRED_](#ops-manager-api-access-token-required)
    - [CA Certificate for Ops Manager _REQUIRED_](#ca-certificate-for-ops-manager-required)
    - [CA Certificate for MongoDB Deployments _HIGHLY ENCOURAGED_](#ca-certificate-for-mongodb-deployments-highly-encouraged)
    - [TLS PEM Files for MongoDB Deployments _HIGHLY ENCOURAGED_](#tls-pem-files-for-mongodb-deployments-highly-encouraged)
    - [MongoDB First User _REQUIRED_](#mongodb-first-user-required)
  - [External Access, Services and Horizons](#external-access-services-and-horizons)
  - [Encryption At Rest](#encryption-at-rest)
  - [Set Up](#set-up)
    - [replicaSetName](#replicasetname)
    - [mongoDBVersion](#mongodbversion)
    - [logLevel](#loglevel)
    - [opsManager.tlsEnabled](#opsmanagertlsenabled)
    - [opsManager.baseUrl](#opsmanagerbaseurl)
    - [opsManager.orgId](#opsmanagerorgid)
    - [opsManager.projectName](#opsmanagerprojectname)
    - [opsManager.omSecret](#opsmanageromsecret)
    - [opsManager.caConfigmap](#opsmanagercaconfigmap)
    - [resources.limits.cpu](#resourceslimitscpu)
    - [resources.limits.mem](#resourceslimitsmem)
    - [resources.requests.cpu](#resourcesrequestscpu)
    - [resources.requests.mem](#resourcesrequestsmem)
    - [storage.size](#storagesize)
    - [storage.storageClass](#storagestorageclass)
    - [storage.manageStorage](#storagemanagestorage)
    - [storage.pvSize](#storagepvsize)
    - [storage.hostPath](#storagehostpath)
    - [storage.workerNodes](#storageworkernodes)
    - [tlsEnabled.enabled](#tlsenabledenabled)
    - [tlsEnabled.caConfigMap](#tlsenabledcaconfigmap)
    - [horizon.enabled](#horizonenabled)
    - [horizon.nodePortHost](#horizonnodeporthost)
    - [horizon.nodePortStartValue](#horizonnodeportstartvalue)
    - [horizon.clusterIPStartValue](#horizonclusteripstartvalue)
    - [rootSecret](#rootsecret)
    - [kmip.enabled](#kmipenabled)
    - [kmip.host](#kmiphost)
    - [kmip.port](#kmipport)
  - [Predeployment Checklist](#predeployment-checklist)
  - [Run](#run)

## Description

The series of Helm Charts to deploy MongoDB Enterprise Advanced replica sets within Kubernetes with the MongoDB Kubernetes Operator and Ops Manager.

## Steps to Deploy

1. Ensure [Prerequisites](#prerequisites) are met
2. Create [Ops Manager Access Token](#ops-manager-api-access-token-required) (Progammatic Access)
3. Create Kubernetes `configmap` for [Ops Manager X.509 Certificate Authority (CA) certificate chain](#ca-certificate-for-ops-manager-required)
4. Create Kubernetes `configmap` for [MongoDB deployments CA certificate chain](#ca-certificate-for-mongodb-deployments-highly-encouraged) - if requires - and seriously, this should just be a normal thing
5. Create Kubernets secrets for the [MonogDB instances TLS and cluster authentication](#tls-pem-files-for-mongodb-deployments-highly-encouraged) - once again this is "if requires", but should be just a normal thing.....look at your life choices if you are not doing this!
6. Create a Kubernetes secret for the [`root`](mongodb-first-user-required) user of the MongoDB deployment
7. Create the `values.yaml` file for the deployment.


## Prerequisites

The [MongoDB Enterprise Kubernetes Operator](https://docs.mongodb.com/kubernetes-operator/master/) and [MongoDB Ops Manager](https://docs.opsmanager.mongodb.com/current/application/) must be installed and operation. The Kubernetes Operator must be able to communicate with Ops Manager. Instructions on installing the MongoDB Kubernetes Operator can be found in the MongoDB [documentation](https://docs.mongodb.com/kubernetes-operator/master/installation/). MongoDB Ops Manager should be installed by the MongoDB Professional Services team so it is installed and configured securely and correctly.

[Helm](https://helm.sh/docs/intro/install/) is required to be installed and [Helmfile](https://github.com/roboll/helmfile) is also highly recommended. If Helmfile is used you will also need [Helm-Diff](https://github.com/databus23/helm-diff).

## Deployment Requirements

### Ops Manager API Access Token _REQUIRED_

Within Ops Manager, an Organisation-level API token must be created with the `Organisation Owner` privilege (WIP) for the organisation that is going to be used for MongoDB deployments. The MongoDB [documentation](https://docs.opsmanager.mongodb.com/current/tutorial/manage-programmatic-api-keys/#create-an-api-key-in-an-organization) explains how to create an Organisational-level API token (key pair).

The following illustrates how to create the Kubernetes secret for the access token:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret generic <name-of-secret> \
  --from-literal=publicKey=<publicKey> \
  --from-literal=privateKey=<privateKey>
```

Confusingly the `publicApiKey` is actually set to the value of the `privateKey` portion of the access token.

The name of this secret must be set to the value of the `opsManager.omSecret` key in the relevant `values.yaml` file. This can be a common configmap if more than one deployment is in a Kubernetes namespace and Ops Manager Organisation.

### CA Certificate for Ops Manager _REQUIRED_

This is **REQUIRED** because your Ops Manager should be using TLS!

The certificate must include the whole certificate chain of the Certificate Authority that signed the X.509 certificate for Ops Manager.

This can be a common configmap if more than one deployment is in a Kubernetes namespace and Ops Manager Organisation.

This is stored in a configMap is set in the relevant `values.yaml` as `opsManager.caConfigMap`. The name of the key in the configmap **MUST** be `mms-ca.crt`, this can be created via:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create configmap <name-of-configmap> \
  --from-file=mms-ca.crt
```

This is most likely common in all MongoDB deployments.

### CA Certificate for MongoDB Deployments _HIGHLY ENCOURAGED_

The certificate must include the whole certificate chain of the Certificate Authority that signed the X.509 certificate for pods. 

This is stored in a configMap is set in the relevant values.yaml as tls.caConfigMap. The name of the key in the configmap **MUST** be `ca-pem`, this can be created via:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create configmap <name-of-configmap> \
  --from-file=ca-pem
```

This is most likely common in all MongoDB deployments.

**REQUIRED** if `tls.enabled` is `true`.

### TLS PEM Files for MongoDB Deployments _HIGHLY ENCOURAGED_

This requires two secrets: one for the client communications and one for cluster communications.

The secrets contain the X.509 key and certificate. One key/certificate pair is used for all members of the replica set, therefore a Subject Alternate Name (SAN) entry must exist for each member of the replica set. The SANs will be in the form of:

**\<replicaSetName\>-\<X\>.\<replicaSetName\>.\<namespace\>**

Where `<replicaSetName>` is the `replicaSetName` in the `values.yaml` for your deployment and `<X>` is the 0-based number of the pod.

The certificates must include the name of FQDN external to Kubernetes as a Subject Alternate Name (SAN) if external access is required. 

The secrets must be named as follows:

**\<replicaSetName\>-\<cert\>**

**\<replicaSetName\>-\<clusterfile\>**

The two secrets can be created as follows:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret tls <replicaSetName>-cert \
  --cert=<path-to-cert> \
  --key=<path-to-key>

kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret tls <replicaSetName>-clusterfile \
  --cert=<path-to-cert> \
  --key=<path-to-key>
```

**REQUIRED** if `tls.enabled` is `true`.

### MongoDB First User _REQUIRED_

A secret must exist for the first user in MongoDB. This will be a user with the `root` role. The name of the secret must be set in the releveant `values.yaml` as `rootSecret` value. The secret must contain a key called `password` that contains the password for the user. The user name is set to `<replicaSetName>-root`, where `<replicaSetName>` is the value `replicaSetName` in the relevant `values.yaml` file.

The secret can be create via `kubectl` as follows:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret generic <name-of-secret> \
  --from-literal=password=<password>
```

The name of the user that is created has the pattern of **ap-\<replicaSetName\>-root**, where `<replicaSetName>` is the `replicaSetName` in the `values.yaml` for your deployment.


## External Access, Services and Horizons

If external access (e.g. access from external to Kubernetes) is required a NodePort service is created for each replica set member and a MongoDB Split Horizon associated with each replica set member. The MongoDB Split Horizon provides a different view of the cluster when `isMaster` is exeecuted depending on the address used in the connection string. This allows the discovery process to present the addresses of the replica set members as they should be viewed external to Kubernetes.

A Kubernetes worker node or other address that is resolved to a worker needs (or load balancer) to be allocated as the `horizons.nodePortHost` value along with a starting port number, `horizons.nodePortStartValue`, which will be automatically incremented for every member of the replica set, e.g. starting at 30000, the second member of the replica set will be given the external port number of 30001. The service will also be allocated an IP address internal to Kubernetes, the starting IP address needs to be set as the `horizon.clusterIPStartValue` value. This addressed will be incremented by one for each subsequent pod in the replica set. There is no fancy checks to determine if the addresses are valid. The address range must be a valid address range for services in Kuberenetes and cannot be used anywhere else in the Kubernetes cluster.

In most Kubernetes environments the port range is 30000 to 32767. The port numbers cannot overlap with port numbers already in use in any deployment of any kind in the Kubernetes cluster.

To access from external to Kubernetes the connection string for a three-member replica set would look similar to:

```shell
mongodb://<nodePortHost>:<nodePortStartValue + 0>,<nodePortHost>:<nodePortStartValue + 1>,<nodePortHost>:<nodePortStartValue + 2>/?replicaSet=<replicaSetName>
```

e.g.
```shell
mongodb://workernode5.mongodb.local:30000,workernode5.mongodb.local:30001,workernode5.mongodb.local:30002/?replicaSet=ap-mongodb-dev
```

## Encryption At Rest

If encryption at rest is required the `kmp.enabled` value in the relevant `values.yaml` file must be set to `true`.

Ensure to set the FQDN (`kmip.host`) and port (`kmip.port`) of the KMIP device/service.

The pod's X.509 PEM file can CA certificate will be used for authentication to the KMIP device/service.

## Set Up

Two environment variables are required, called ENV and NS (both case senstive). The first describes the selected Git environment for deployment and the second describes the Kubernetes namespace.

The variables for each deployment are contained in the `values.yaml`. The `values.yaml` file for the selected environment must reside in a directory under `charts/values/<ENV>` such as `charts/values/dev/values.yaml` or `charts/values/production/values.yaml`. Each **\<ENV\>** directory will be a different deployment. The `examples` directory contains an examples `values.yaml` file, plus there are examples under the `charts/values` directory so the reader can see the structure.

The following table describes the values required in the relevant `values.yaml`:

|Key|Purpose|
|--------------------------|------------------------------------|
|replicaSetName|Name of the cluster, used for naming the pods and replica set name|
|mongoDBVersion|The version of MongoDB to installed, such as `4.4.8-ent` for MognoDB Enterprise 4.4.8|
|replicas|Number of members in the replica set (integer)|
|logLevel|Level of logging for MongoDB and agents, INFO or DEBUG|
|opsManager.tlsEnabled|Boolean determining if TLS is used to communicate from the Operator and Agents to Ops Manager|
|opsManager.baseUrl|The URL, including protocol and port, of Ops Manager|
|opsManager.orgId|The ID of the Organisation in Ops Manager that the project will be created|
|opsManager.projectName|The name of the project that will be created or used in Ops Manager for the MongoDB deployment|
|opsManager.omSecret|The name of the secret that contains the credentials token for the Ops Manager API for the selected Organisation|
|opsManager.caConfigmap|The name of the configmap that contains the CA certificate used to communicate with Ops Manager|
|resources.limits.cpu|The max CPU the containers can be allocated|
|resources.limits.mem|The max memory the containers can be allocated, include units|
|resources.requests.cpu|The initial CPU the containers can be allocated|
|resources.requests.mem|The initial memory the containers can be allocated, include units|
|storage.size|The size of the volume for storage, include units|
|storage.storageClass|The name of the StorageClass to use for the PersistentVolumes. Default is ""|
|storage.manageStorage|Boolean to determine if the storageClass and persistentVolumes are created and managed|
|storage.pvSize|The size, including units of the presistenVolume to create and manage|
|storage.hostPath|The path of the workernode that will be used for the local PersistentVolume|
|storage.workerNodes|An array of worker nodes that will be used for the local PersistentVolumes|
|tlsEnabled.enabled|Boolean describing if TLS is used in the cluster. (This should always be true)|
|tlsEnabled.caConfigMap|Name of the configMap for the CA certificate|
|horizon.enabled|Boolean determining of MongoDB Split Horizon is enabled|
|horizon.nodePortStartValue|Intger of the starting value for NodePorts and Horizons|
|horizon.nodePortHost|FQDN of either a worker node or other resolvable address that will be the basis of the MongoDB Split Horizon|
|horizon.clusterIPStartValue|The starting IP address used as the first IP address for the ClusterIPs. Each subsequent pod will have the IP address incremented by one|
|rootSecret|The secret containing the MongoDB first user|
|kmip.enabled|Boolean determining if KMIP is enabled for the MongoDB deployment|
|kmip.host|The host address of the KMIP device|
|kmip.port|The port of the KMIP device|

### replicaSetName

The name to be used for the replica set. The name should be included in the MongoDB connection string when connecting to the replica set, especially from external to Kubernetes, so split horizon functions correctly.

### mongoDBVersion

The version of MongoDB to deploy. The form is **\<major\>.\<release-series\>.\<patch\>-ent**, such as `4.4.7-ent` for Enterprise versions. We do not encourage using odd numbers for the release series value, as these are development series.

As of MongoDB 5.0 the versioning has changed to **\<major\>.\<rapid\>.\<patch\>-ent**, where the rapid is a quarterly release of new features and not a develop/stable differentiator anymore.

### logLevel

Log level for the MongoDB instance and automation agent. Can be `DEBUG` or `INFO`. In the case of `DEBUG` this is equivalent to `2` for `systemLog.verbosity` in the MongoDB config file.

### opsManager.tlsEnabled

Boolean value determining if Ops Manager uses TLS for data in transit. Should **ALWAYS** be `true`.

### opsManager.baseUrl

The URL of the Ops Manager, including the protocol and port number, such as `https://ops-manager.mongodb.local:8443`.

### opsManager.orgId

The ID of the Ops Manager Organisation. The can be found in Ops Manager by browsng to the Organisation and selecting the Organisation ID in the URL. such as `5e439737e976cc5e50a7b13d`.

Read the MongoDB [documentation](https://docs.opsmanager.mongodb.com/current/tutorial/manage-organizations/) to learn how to create or manage an Organisation in Ops Manager.

### opsManager.projectName

The name of the Ops Manager Project within the selected Organisation that will be created/used for the MongoDB Deployment.

### opsManager.omSecret

The is the name of the secret that contains the token key pair for Ops Manager API access that is used by the MongoDB Kubernetes Operator to manage the deployment(s).

This can be a common configmap if more than one deployment is in a Kubernetes namespace and Ops Manager Organisation.

See the [Deployment Requirements](#ops-manager-api-access-token-required) section for details on creating the API access token.

### opsManager.caConfigmap

The name of the configmap that contains the X.509 certificate of the Certificate Authority that use used for TLS communications to and from Ops Manager.

This can be a common configmap if more than one deployment is in a Kubernetes namespace.

See the [Deployment Requirements](#ca-certificate-for-ops-manager-required) section for details on creating this configmap.


### resources.limits.cpu

The maximum number of CPUs that can be assigned to each pod specified as either an integer, float, or with the `m` suffix (for milliCPUS).

### resources.limits.mem

The maximum memory that can be assigned to each pod. The units suffix can be one of the following: E, P, T, G, M, K, Ei, Pi, Ti, Gi, Mi, Ki.

### resources.requests.cpu

The initial number of CPUs that is assigned to each pod specified as either an integer, float, or with the `m` suffix (for milliCPUS).

### resources.requests.mem

The initial memory that is assigned to each pod. The units suffix can be one of the following: E, P, T, G, M, K, Ei, Pi, Ti, Gi, Mi, Ki.

### storage.size

The persistent storage that is assigned to each pod. The units suffix can be one of the following: E, P, T, G, M, K, Ei, Pi, Ti, Gi, Mi, Ki.

### storage.storageClass

The name of the storage class that is used to create the persistentVolumeClaims.

### storage.manageStorage

A boolean to determine if the `storageClass` and `persistenVolumes` for the deployments are also managed by Helm.

### storage.pvSize

The size of the persistentVolume that will be created, if managed by Helm. The units suffix can be one of the following: E, P, T, G, M, K, Ei, Pi, Ti, Gi, Mi, Ki.

### storage.hostPath

The absolute path of a directory on the worker nodes to use as the persistentVolume path, if storage is managed by Helm.

### storage.workerNodes

An array of worker node names that will have persistentVolumes created on if storage is managed by Helm. The names of the worker nodes must in the same format as what is returned by `kubectl get node`.

### tlsEnabled.enabled

A boolean to determine if TLS is enabled for MongoDB deployments, which is should be!

### tlsEnabled.caConfigMap

The name of the configmap that contains the X.509 certificate of the Certificate Authority that use used for TLS communications to and from the MongoDB instances.

See the [Deployment Requirements](#ca-certificate-for-mongodb-deployments-highly-encouraged) section for details on creating this configmap.

### horizon.enabled

A boolean to determine if external access, and therefore Split Horizon, is required/enabled.

### horizon.nodePortHost

The name of a Kubernetes worker node or CNAME that resolves to a worker node, or a load balancer, that is used as the external access point for Kubernetes services. This will be used as the Split Horizon access hostname and part of the MongoDB connection string external to Kuberntes.

### horizon.nodePortStartValue

The port number to start will as the base for the Split Horizon ports. Most be in the range of 30000 to 32767 and must be able to accommodate the number of members for the replica set, e.g. 30000 can be used for a three-member replica set but 32767 cannot because 32767 is the maximum.

The base number and subsequent numbers cannot already be used in the Kubernetes cluster by any other NodePort.

### horizon.clusterIPStartValue

As part of making the NodePort service, the service will also be allocated an IP address internal to Kubernetes. This addressed will be incremented by one for each subsequent pod in the replica set. There is no fancy checks to determine if the addresses are valid. The address range must be a valid address range for services in Kuberenetes and cannot be used anywhere else in the Kubernetes cluster. 

### rootSecret

This is the secret name that contains the password for the first user.

See the [Deployment Requirements](#mongodb-first-user-required) section for details on creating this secret.

### kmip.enabled

A boolean value to determine if KMIP is used to perform encryption at rest within the MongoDB deployments.

### kmip.host 

The FQDN if the KMIP device/service.

### kmip.port

The port number of the KMIP device/service, normally 5696.

## Predeployment Checklist

Ensure all the following as satisfied before attempoting to deploy:

- [ ] Create a new directory under the `charts/'values` directory for the environment
- [ ] Copy the example `values.yaml` file from the `examples` directory to the new directory
- [ ] Ops Manager API Access Token created
- [ ] Ops Manager API Access Token secret created
- [ ] Ops Manager CA Certificate secret created
- [ ] MongoDB deployment CA certificate configmap created (recommended)
- [ ] MongoDB deployment TLS certificate secret created (recommended)
- [ ] Password secret for the first user created
- [ ] Configure external access (horizons) if required
- [ ] Ensure all values in the relevant `values.yaml` file set

## Run

To use the Helm charts via helmfile perform the following:

```shell
ENV=dev NS=mongodb KUBECONFIG=$PWD/kubeconfig helmfile apply
```

The `kubeconfig` is the config file to gain access to the Kubernetes cluster. The `ENV=dev` is the environment to use for the `values.yaml`, in this case an environment called `dev`.

To see what the actual YAML files will look like without applying them to Kubernetes use:

```shell
ENV=dev helmfile template
```

To destroy the environment (the PersistentVolumes will remain) use the following command:

```shell
ENV=dev NS=mongodb KUBECONFIG=$PWD/kubeconfig helmfile destroy
```