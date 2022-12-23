# k8s_mdb

## Table of Contents
- [k8s\_mdb](#k8s_mdb)
  - [Table of Contents](#table-of-contents)
  - [Compatability](#compatability)
- [Breaking Changes](#breaking-changes)
- [Description](#description)
- [Steps to Deploy](#steps-to-deploy)
  - [Prerequisites](#prerequisites)
  - [Set Up](#set-up)
  - [Deployment Requirements](#deployment-requirements)
    - [Ops Manager API Access Token _REQUIRED_](#ops-manager-api-access-token-required)
    - [CA Certificate for Ops Manager _REQUIRED_](#ca-certificate-for-ops-manager-required)
- [Settings](#settings)
  - [Common Settings](#common-settings)
    - [CA Certificate for MongoDB Deployments _HIGHLY ENCOURAGED_](#ca-certificate-for-mongodb-deployments-highly-encouraged)
    - [tlsEnabled.enabled](#tlsenabledenabled)
    - [tlsEnabled.caConfigMap](#tlsenabledcaconfigmap)
    - [MongoDB First User _REQUIRED_](#mongodb-first-user-required)
    - [LDAP Authentication and Authorisation](#ldap-authentication-and-authorisation)
    - [Options](#options)
      - [clusterName](#clustername)
      - [mongoDBVersion](#mongodbversion)
      - [mongoDBFCV](#mongodbfcv)
      - [logLevel](#loglevel)
      - [auth.scram.enabled](#authscramenabled)
      - [auth.allowNoManagedUsers](#authallownomanagedusers)
      - [auth.ldap.enabled](#authldapenabled)
      - [auth.ldap.servers](#authldapservers)
      - [auth.ldap.ldaps](#authldapldaps)
      - [auth.ldap.caConfigMap](#authldapcaconfigmap)
      - [auth.ldap.bindUserDN](#authldapbinduserdn)
      - [auth.ldap.bindUserSecret](#authldapbindusersecret)
      - [auth.ldap.userToDNMapping](#authldapusertodnmapping)
      - [auth.ldap.authzQueryTemplate](#authldapauthzquerytemplate)
      - [opsManager.tlsEnabled](#opsmanagertlsenabled)
      - [opsManager.baseUrl](#opsmanagerbaseurl)
      - [opsManager.orgId](#opsmanagerorgid)
      - [opsManager.projectName](#opsmanagerprojectname)
      - [opsManager.omSecret](#opsmanageromsecret)
      - [opsManager.caConfigmap](#opsmanagercaconfigmap)
      - [mongoDBAdminPasswdSecret](#mongodbadminpasswdsecret)
      - [additionalUsers](#additionalusers)
  - [Replica Set Specific Settings](#replica-set-specific-settings)
    - [TLS X.509 Certificates for MongoDB Deployments _HIGHLY ENCOURAGED_](#tls-x509-certificates-for-mongodb-deployments-highly-encouraged)
    - [Replica Set External Access, Services and Horizons](#replica-set-external-access-services-and-horizons)
    - [Encryption At Rest - this is currently non-fucntional due to changes](#encryption-at-rest---this-is-currently-non-fucntional-due-to-changes)
    - [Options](#options-1)
      - [replicaSet.resources.limits.cpu](#replicasetresourceslimitscpu)
      - [replicaSet.resources.limits.mem](#replicasetresourceslimitsmem)
      - [replicaSet.resources.requests.cpu](#replicasetresourcesrequestscpu)
      - [replicaSet.resources.requests.mem](#replicasetresourcesrequestsmem)
      - [replicaSet.storage.persistenceType](#replicasetstoragepersistencetype)
      - [replicaSet.storage.nfs](#replicasetstoragenfs)
      - [replicaSet.storage.nfsInitImage](#replicasetstoragenfsinitimage)
      - [replicaSet.storage.single.size](#replicasetstoragesinglesize)
      - [replicaSet.storage.single.storageClass](#replicasetstoragesinglestorageclass)
      - [replicaSet.storage.multi.data.size](#replicasetstoragemultidatasize)
      - [replicaSet.storage.multi.data.storageClass](#replicasetstoragemultidatastorageclass)
    - [replicaSet.storage.multi.journal.size](#replicasetstoragemultijournalsize)
    - [replicaSet.storage.multi.journal.storageClass](#replicasetstoragemultijournalstorageclass)
    - [replicaSet.storage.multi.logs.size](#replicasetstoragemultilogssize)
    - [replicaSet.storage.multi.logs.storageClass](#replicasetstoragemultilogsstorageclass)
    - [extAccess.enabled](#extaccessenabled)
    - [extAccess.exposeMethod](#extaccessexposemethod)
    - [extAccess.ports](#extaccessports)
    - [extAccess.ports\[n\].horizonName](#extaccessportsnhorizonname)
    - [extAccess.ports\[n\].port](#extaccessportsnport)
    - [extAccess.ports\[n\].clusterIP](#extaccessportsnclusterip)
    - [kmip.enabled](#kmipenabled)
    - [kmip.host](#kmiphost)
    - [kmip.port](#kmipport)
  - [Sharded Cluster Specific SettingsThe following are settings required if a replica set is to be deployed.](#sharded-cluster-specific-settingsthe-following-are-settings-required-if-a-replica-set-is-to-be-deployed)
    - [TLS X.509 Certificates for MongoDB Deployments _HIGHLY ENCOURAGED_](#tls-x509-certificates-for-mongodb-deployments-highly-encouraged-1)
      - [Shard Members](#shard-members)
      - [Config Server Replica Set](#config-server-replica-set)
      - [Mongos](#mongos)
  - [Predeployment Checklist](#predeployment-checklist)
  - [Run](#run)

## Compatability

This version of the Helm charts has been tested with MongoDB Kubernetes Operator version(s):
* 1.16.x
* 1.17.x

# Breaking Changes

This version adds values for sharded clusters and moves replica set-specific settings to its own object.

# Description

The series of Helm Charts to deploy MongoDB Enterprise Advanced replica sets within Kubernetes with the MongoDB Kubernetes Operator and Ops Manager.

The `/examples` directory has `values.yaml` examples for replica sets and sharded clusters.

# Steps to Deploy

1. Ensure [Prerequisites](#prerequisites) are met
2. Create [Ops Manager Access Token](#ops-manager-api-access-token-required) (Progammatic Access)
3. Create Kubernetes `configmap` for [Ops Manager X.509 Certificate Authority (CA) certificate chain](#ca-certificate-for-ops-manager-required)
4. Create Kubernetes `configmap` for [MongoDB deployments CA certificate chain](#ca-certificate-for-mongodb-deployments-highly-encouraged) - if requires - and seriously, this should just be a normal thing
5. Create Kubernets secrets for the [MonogDB instances TLS and cluster authentication](#tls-pem-files-for-mongodb-deployments-highly-encouraged) (for replica sets) or [MongoDB Sharded Clusters with TLS]() (for shardedc clusters)- once again this is "if requires", but should be just be a normal thing.....look at your life choices if you are not doing this!
6. Create a Kubernetes secret for the [`root`](mongodb-first-user-required) user of the MongoDB deployment
7. Create the `values.yaml` file for the deployment.


## Prerequisites

The [MongoDB Enterprise Kubernetes Operator](https://docs.mongodb.com/kubernetes-operator/master/) and [MongoDB Ops Manager](https://docs.opsmanager.mongodb.com/current/application/) must be installed and operation. The Kubernetes Operator must be able to communicate with Ops Manager. Instructions on installing the MongoDB Kubernetes Operator can be found in the MongoDB [documentation](https://docs.mongodb.com/kubernetes-operator/master/installation/). MongoDB Ops Manager should be installed by the MongoDB Professional Services team so it is installed and configured securely and correctly.

[Helm](https://helm.sh/docs/intro/install/) is required to be installed and [Helmfile](https://github.com/roboll/helmfile) is also highly recommended. If Helmfile is used you will also need [Helm-Diff](https://github.com/databus23/helm-diff).

These Helm charts assume PVs and Storage classes already exist within the Kubernetes cluster.


## Set Up

Two environment variables are required, called `ENV` and `NS` (both case senstive). The first describes the selected environment for deployment, which correspondes to a directory under the `values` directory, and the second describes the Kubernetes namespace.

The variables for each deployment are contained in the `values.yaml`. The `values.yaml` file for the selected environment must reside in a directory under `values/<ENV>` such as `values/dev/values.yaml` or `values/production/values.yaml`. Each **\<ENV\>** directory will be a different deployment. The `examples` directory contains an examples `values.yaml` file, plus there are examples under the `values` directory so the reader can see the structure.

## Deployment Requirements

### Ops Manager API Access Token _REQUIRED_

Within Ops Manager, an Organisation-level API token must be created with the `Organisation Owner` privilege (WIP) for the organisation that is going to be used for MongoDB deployments. The MongoDB [documentation](https://docs.opsmanager.mongodb.com/current/tutorial/manage-programmatic-api-keys/#create-an-api-key-in-an-organization) explains how to create an Organisational-level API token (key pair). Ensure that the CIDR range that will be used by the Kubernetes Operator is included in the API Access List.

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

# Settings

## Common Settings

### CA Certificate for MongoDB Deployments _HIGHLY ENCOURAGED_

The certificate must include the whole certificate chain of the Certificate Authority that signed the X.509 certificate for pods. 

This is stored in a configMap is set in the relevant values.yaml as tls.caConfigMap. The name of the key in the configmap **MUST** be `ca-pem`, this can be created via:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create configmap <name-of-configmap> \
  --from-file=ca-pem
```

This is most likely common in all MongoDB deployments.

**REQUIRED** if `tls.enabled` is `true`.

### tlsEnabled.enabled

A boolean to determine if TLS is enabled for MongoDB deployments, which is should be!

### tlsEnabled.caConfigMap

The name of the configmap that contains the X.509 certificate of the Certificate Authority that use used for TLS communications to and from the MongoDB instances.

See the [Deployment Requirements](#ca-certificate-for-mongodb-deployments-highly-encouraged) section for details on creating this configmap.

### MongoDB First User _REQUIRED_

A secret must exist for the first user in MongoDB. This will be a user with the `root` role. The name of the secret must be set in the releveant `values.yaml` as `mongoDBAdminPasswdSecret` value. The secret must contain a key called `password` that contains the password for the user. The username is set to `root`.

The secret can be create via `kubectl` as follows:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret generic <name-of-secret> \
  --from-literal=password=<password>
```

The name of the user that is created has the pattern of **ap-\<clusterName\>-root**, where `<clusterName>` is the `clusterName` in the `values.yaml` for your deployment.

### LDAP Authentication and Authorisation

If LDAP authentication and authorisation is required the `auth.ldap.enabled` must be set to `true`. MongoDB highly recommends that `ldaps` is used to protect the credentials of users, therefore `auth.ldap.ldaps` should also be `true`.

A bind user must be provided and a secret created for their password, the key within the secret must be `password`. The following is an example to create the secret:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret generic <name-of-secret> \
  --from-literal=password=<password>
```

If LDAPS is selected the CA certificate used with the LDAP servers must be provided within a configmap. The name of the key within the configmap **MUST** be `ca-pem`. This can be achieved by:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create configmap <name-of-configmap> \
  --from-file=ca-pem
```

To map from the username used by the MongoDB user to the Distingiushed Name (DN) within LDAP a mapping query must be provided. MongoDB Professional Services can assist with this, but the following is an example of the query for a user that logs on a USER@MONGODB.LOCAL but their DN is actually `cn=USER,cn=Users,dc=mongodb,dc=local`:

```shell
'[{ match: "(.+)@MONGODB.LOCAL", substitution: "cn={0},cn=Users,dc=mongodb,dc=local"}]'
```

If LDAP authorisation is desired query must be provided to determine the groups of the user. In the following example the user's groups are held in the `memberOf` LDAP attribute of the user:

```shell
'{USER}?memberOf?base'
```

If LDAP authorisation is not required this setting can be skipped.

### Options

The following table describes the common values required in the relevant `values.yaml` for both replica sets and sharded clusters:

|Key|Purpose|
|--------------------------|------------------------------------|
|clusterName|Name of the cluster, used for naming the pods and replica set name|
|mongoDBVersion|The version of MongoDB to installed, such as `5.0.8-ent` for MongoDB Enterprise 5.0.8 Enterprise Advanced|
|mongoDBFCV|A string describing the Feature Compatibility Version of the deployment, default is "5.0"|
|logLevel|Level of logging for MongoDB and agents, INFO or DEBUG|
|auth.scram.enabled|Boolean to determine if SCRAM authentication is selected. Can be selected with `auth.ldap.enabled` or by itself. At least one method must be selected|
|auth.allowNoManagedUsers|Boolean to determine if users not managed by Kubernetes are allowed|
|auth.ldap.enabled|Boolean to determine if LDAP authentication is selected. Can be selected with `auth.scram.enabled` or by itself. At least one method must be selected|
|auth.ldap.servers|An array of LDAP servers to use for authentication (and possibly authoisation)|
|auth.ldap.ldaps|Boolean to determine if `ldaps` is selected for the LDAP protocol, which it should be always|
|auth.ldap.caConfigMap|The name of the configmap in Kubernetes containing the CA certificate for the LDAP server(s)|
|auth.ldap.bindUserDN|The Distinguished Name (DN) of the LDAP bind user|
|auth.ldap.bindUserSecret|The Kubernetes secret containing the password of the bind user|
|auth.ldap.userToDNMapping|The LDAP mapping to convert from the name used to log into MongoDB to what is actually used in LDAP|
|auth.ldap.authzQueryTemplate|The LDAP Query Template used to perform the lookup for a user's groups|
|opsManager.tlsEnabled|Boolean determining if TLS is used to communicate from the Operator and Agents to Ops Manager|
|opsManager.baseUrl|The URL, including protocol and port, of Ops Manager|
|opsManager.orgId|The ID of the Organisation in Ops Manager that the project will be created|
|opsManager.projectName|The name of the project that will be created or used in Ops Manager for the MongoDB deployment|
|opsManager.omSecret|The name of the secret that contains the credentials token for the Ops Manager API for the selected Organisation|
|opsManager.caConfigmap|The name of the configmap that contains the CA certificate used to communicate with Ops Manager|
|tlsEnabled.enabled|Boolean describing if TLS is used in the cluster. (This should always be true)|
|tlsEnabled.caConfigMap|Name of the configMap for the CA certificate|
|mongoDBAdminPasswdSecret|The secret containing the MongoDB first user|
|additionalUsers[n]|Array of additional database users to create|
|additionalUsers[n].username| Username of the database user to manage|
|additionalUsers[n].passwdSecret|The secret name that contains the password for the user|
|additionalUsers[n].roles[m]|Array of roles for the user, consisting of a `db` and the `role`|
|kmip.enabled|Boolean determining if KMIP is enabled for the MongoDB deployment|
|kmip.host|The host address of the KMIP device|
|kmip.port|The port of the KMIP device|

#### clusterName

The name to be used for the replica set. The name should be included in the MongoDB connection string when connecting to the replica set, especially from external to Kubernetes, so split horizon functions correctly.

#### mongoDBVersion

The version of MongoDB to deploy. The form is **\<major\>.\<release-series\>.\<patch\>-ent**, such as `5.0.17-ent` for Enterprise versions. We do not encourage using odd numbers for the release series value, as these are development series.

As of MongoDB 5.0 the versioning has changed to **\<major\>.\<rapid\>.\<patch\>-ent**, where the rapid is a quarterly release of new features and not a develop/stable differentiator anymore.


#### mongoDBFCV

The Feature Compatibility Version of the deployment. Can only ever at or one major version below the currently installed MongoDB version.

Is a string value.

Default is "5.0"

#### logLevel

Log level for the MongoDB instance and automation agent. Can be `DEBUG` or `INFO`. In the case of `DEBUG` this is equivalent to `2` for `systemLog.verbosity` in the MongoDB config file.

#### auth.scram.enabled

Boolean value to determine if SCRAM authentication is enabled. Both `auth.scram.enabled` and `auth.ldap.enabled` can be selected, or just one, but at least one must be `true`.

#### auth.allowNoManagedUsers

Boolean value to determine if users *NOT* managed by Kuberentes are allowed. This can include via `mongorestore` or via `mongosh` etc. If this is `false` Ops Manager will remove any non-Kubernetes managed users.

Default is `true`

#### auth.ldap.enabled

Boolean value to determine if LDAP authentication is enabled. Both `auth.scram.enabled` and `auth.ldap.enabled` can be selected, or just one, but at least one must be `true`.

#### auth.ldap.servers

An array of LDAP servers to use for LDAP authentication (and authorisation of selected). Required if `auth.ldap.enabled` is `true`.

#### auth.ldap.ldaps

A boolean to determine if LDAPS is used as the protocol instead of unsafe LDAP. This should always be `true`. Required if `auth.ldap.enabled` is `true`.

#### auth.ldap.caConfigMap

The configmap name of the CA certificate used with the LDAP servers. Required if `auth.ldap.enabled` is `true` and `auth.ldap.ldaps` is `true`.

The name of the key within the configmap must be `ca-pem`.

#### auth.ldap.bindUserDN

The Distigiushed Name (DN) of the bind user that is used to perform lookups in the directory directory. Required if `auth.ldap.enabled` is `true`.

#### auth.ldap.bindUserSecret

The name of the Kubernetes secret that contains the password of the bind user. The key within the secret must be `password`. Required if `auth.ldap.enabled` is `true`.

#### auth.ldap.userToDNMapping

The mapping to convert the username to the name in the LDAP directory. Required if `auth.ldap.enabled` is `true`.

See the [LDAP](#ldap-authentication-and-authorisation) section for more details.

#### auth.ldap.authzQueryTemplate

The LDAP query to lookup a user's groups within the LDAP directory. Required if `auth.ldap.enabled` is `true`.

See the [LDAP](#ldap-authentication-and-authorisation) section for more details.

#### opsManager.tlsEnabled

Boolean value determining if Ops Manager uses TLS for data in transit. Should **ALWAYS** be `true`.

#### opsManager.baseUrl

The URL of the Ops Manager, including the protocol and port number, such as `https://ops-manager.mongodb.local:8443`.

#### opsManager.orgId

The ID of the Ops Manager Organisation. The can be found in Ops Manager by browsng to the Organisation and selecting the Organisation ID in the URL. such as `5e439737e976cc5e50a7b13d`.

Read the MongoDB [documentation](https://docs.opsmanager.mongodb.com/current/tutorial/manage-organizations/) to learn how to create or manage an Organisation in Ops Manager.

#### opsManager.projectName

The name of the Ops Manager Project within the selected Organisation that will be created/used for the MongoDB Deployment.

#### opsManager.omSecret

The is the name of the secret that contains the token key pair for Ops Manager API access that is used by the MongoDB Kubernetes Operator to manage the deployment(s).

This can be a common configmap if more than one deployment is in a Kubernetes namespace and Ops Manager Organisation.

See the [Deployment Requirements](#ops-manager-api-access-token-required) section for details on creating the API access token.

#### opsManager.caConfigmap

The name of the configmap that contains the X.509 certificate of the Certificate Authority that use used for TLS communications to and from Ops Manager.

This can be a common configmap if more than one deployment is in a Kubernetes namespace.

See the [Deployment Requirements](#ca-certificate-for-ops-manager-required) section for details on creating this configmap.

#### mongoDBAdminPasswdSecret

This is the secret name that contains the password for the first user.

See the [Deployment Requirements](#mongodb-first-user-required) section for details on creating this secret.

#### additionalUsers

This is an array of additional data base users to create. The format is as follows:

```yaml
additionalUsers:
  - username: oplog0-om-user
    passwdSecret: om-user
    roles:
      - db: admin
        role: "clusterMonitor"
      - db: admin
        role: "readWriteAnyDatabase"
      - db: admin
        role: "userAdminAnyDatabase"
```

The `username` must be unique in the database. The `passwdSecret` is a reference to a Kubernetes Secret containing the user password. Just like the [first user](#mongodb-first-user-required), we can use the same Kubernetes command to create the Secret:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret generic <name-of-secret> \
  --from-literal=password=<password>
```

Each entry in the array will create a new MongoDB User (MDBU) resource in Kubernetes named:

**\<clusterName\>-\<username\>**

This is important to remember of creating the blockstore or oplogstore for Ops Manager as the MDBU resource name is required.

## Replica Set Specific Settings

The following are settings required if a replica set is to be deployed.

To ensure a replica set is deployed set the following:

```
replicaSet:
  enabled: true
sharding:
  enabled: false
```

The `sharding.enabled` takes precedence over the the `replicaSet.enabled` setting.

### TLS X.509 Certificates for MongoDB Deployments _HIGHLY ENCOURAGED_

This requires two secrets: one for the client communications and one for cluster communications.

The secrets contain the X.509 key and certificate. One key/certificate pair is used for all members of the replica set, therefore a Subject Alternate Name (SAN) entry must exist for each member of the replica set. The SANs will be in the form of:

**\<clusterName\>-\<X\>.\<clusterName\>-svc.\<namespace\>.svc.cluster.local**

Where `<clusterName>` is the `clusterName` in the `values.yaml` for your deployment and `<X>` is the 0-based number of the pod.

The certificates must include the name of FQDN external to Kubernetes as a Subject Alternate Name (SAN) if external access is required. 

The secrets must be named as follows:

**mdb-<clusterName\>-\<cert\>**

**mdb-<clusterName\>-\<clusterfile\>**

The two secrets can be created as follows:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret tls mdb-<clusterName>-cert \
  --cert=<path-to-cert> \
  --key=<path-to-key>

kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret tls mdb-<clusterName>-clusterfile \
  --cert=<path-to-cert> \
  --key=<path-to-key>
```

**REQUIRED** if `tls.enabled` is `true`.

### Replica Set External Access, Services and Horizons

If external access (e.g. access from external to Kubernetes) is required a NodePort or LoadBalancer service can be created for each replica set member and a MongoDB Split Horizon associated with each replica set member. The MongoDB Split Horizon provides a different view of the cluster when `isMaster` is exeecuted depending on the address used in the connection string. This allows the discovery process to present the addresses of the replica set members as they should be viewed external to Kubernetes.

For a NodePort service, a Kubernetes worker node, or an address that is resolved to a worker node, needs to be allocated as the `replicaSet.extAccess.ports[].horizonName` value along with an associated port for each horizon, `replicaSet.extAccess.ports[].port`. The service will also be allocated an IP address internal to Kubernetes for each NodePort, the IP address is set via the `replicaSet.extAccess.ports[].clusterIP` value. There is no fancy checks to determine if the addresses are valid. The address range must be a valid address range for services in Kuberenetes and cannot be used anywhere else in the Kubernetes cluster. For LoadBalancer service type, the `replicaSet.extAccess.ports[].horizonName` value along with an associated port for each horizon, `replicaSet.extAccess.ports[].port`, are still required, but the port is the port of the load balancer and not the NodePort

In most Kubernetes environments the NodePort port range is 30000 to 32767. The port numbers cannot overlap with port numbers already in use in any deployment of any kind in the Kubernetes cluster.

To access from external to Kubernetes the connection string for a three-member replica set would look similar to:

```shell
mongodb://<horizonName-0>:<port-0>,<horizonName-1>:<port-1>,<horizonName-2>:<port-2>/?replicaSet=<clusterName>
```

e.g.
```shell
mongodb://workernode5.mongodb.local:30000,workernode5.mongodb.local:30011,workernode5.mongodb.local:32002/?replicaSet=ap-mongodb-dev
```

### Encryption At Rest - this is currently non-fucntional due to changes

If encryption at rest is required the `kmp.enabled` value in the relevant `values.yaml` file must be set to `true`.

Ensure to set the FQDN (`kmip.host`) and port (`kmip.port`) of the KMIP device/service.

The pod's X.509 PEM file can CA certificate will be used for authentication to the KMIP device/service.

### Options

The following table describes the values required in the relevant `values.yaml` specifically for replica sets:

|Key|Purpose|
|--------------------------|------------------------------------|
|replicaSet.replicas|Number of members in the replica set (integer)|
|replicaSet.resources.limits.cpu|The max CPU the containers can be allocated|
|replicaSet.resources.limits.mem|The max memory the containers can be allocated, include units|
|replicaSet.resources.requests.cpu|The initial CPU the containers can be allocated|
|replicaSet.resources.requests.mem|The initial memory the containers can be allocated, include units|
|replicaSet.storage.persistenceType|This is either `single` for all data one one partition, or `multi` for separate partiions for `data`, `journal`, and `logs`|
|replicaSet.storage.nfs|Boolean value to determine if NFS if used for persistence storage, which requires a further init container to fix permissions on NFS mount|
|replicaSet.storage.nfsInitImage|Image name a tag for the init container to perform the NFS permissions modification. Defaults to the same init container image as the database|
|replicaSet.storage.single.size|The size of the volume for all storage, include units|
|replicaSet.storage.single.storageClass|The name of the StorageClass to use for the PersistentVolumeClaim for all the storage. Default is ""|
|replicaSet.storage.multi.data.size|The size of the volume for database data storage, include units|
|replicaSet.storage.multi.data.storageClass|The name of the StorageClass to use for the PersistentVolumeClaim for the database data storage. Default is ""|
|replicaSet.storage.multi.journal.size|The size of the volume for database journal, include units|
|replicaSet.storage.multi.journal.storageClass|The name of the StorageClass to use for the PersistentVolumeClaim for the database journal. Default is ""|
|replicaSet.storage.multi.logs.size|The size of the volume for database logs, include units|
|replicaSet.storage.multi.logs.storageClass|The name of the StorageClass to use for the PersistentVolumeClaim for the database logs. Default is ""|
|replicaSet.extAccess.enabled|Boolean determining of MongoDB Split Horizon is enabled|
|replicaSet.extAccess.exposeMethod|The method to expose access MongoDB to clients externally to Kubernetes. The options are `NodePort` or `LoadBalancer`|
|replicaSet.extAccess.ports|Array of objects describing horizone names with associated port addresses, and clouterIP if required. One entry is required per replica set member|
|replicaSet.extAccess.ports[n].horizonName|Name of the MongoDB Horizon for the member|
|replicaSet.extAccess.ports[n].port|The port of the MongoDB horizon. It is either the NodePort port or the LoadBalancer port|
|replicaSet.extAccess.ports[n].clusterIP|The clusterIP of the NodePort. Not required if `LoadBalancer` is the selected method|

#### replicaSet.resources.limits.cpu

The maximum number of CPUs that can be assigned to each pod specified as either an integer, float, or with the `m` suffix (for milliCPUS).

#### replicaSet.resources.limits.mem

The maximum memory that can be assigned to each pod. The units suffix can be one of the following: E, P, T, G, M, K, Ei, Pi, Ti, Gi, Mi, Ki.

#### replicaSet.resources.requests.cpu

The initial number of CPUs that is assigned to each pod specified as either an integer, float, or with the `m` suffix (for milliCPUS).

#### replicaSet.resources.requests.mem

The initial memory that is assigned to each pod. The units suffix can be one of the following: E, P, T, G, M, K, Ei, Pi, Ti, Gi, Mi, Ki.

#### replicaSet.storage.persistenceType

The type of storage for the pod. Select `single` for data, journal, and logs to be on one partition. If this is select both `storage.single.size` and `storage.single.storageClass` must be provided.

If separate partitions are required for data, journal, and logs then select `multi`, and then provide all the following:

* `replicaSet.storage.multi.data.size`
* `replicaSet.storage.multi.data.storageClass`
* `replicaSet.storage.multi.journal.size`
* `replicaSet.storage.multi.journal.storageClass`
* `replicaSet.storage.multi.logs.size`
* `replicaSet.storage.multi.logs.storageClass`

#### replicaSet.storage.nfs

A boolean to determine if NFS is used as the persistent storage. If this is `true` then an additional init container is prepended to the init container array in the statefulSet to that will `chown`` the permissions of the NFS mount to be that of the mongod user. The Kubernetes Operator uses 2000:2000 for the UID and GID of the mongod user.

This init container will run as root so the permissions can be set. This is done via setting the `runAsUser` to `0` and the `runAsNonRoot` to `false`. Ensure you understand the implications of this.

This will chown `/data`, `/journal` and `/var/log/mongodb-mms-automation` to 2000:2000

Default is `false`

#### replicaSet.storage.nfsInitImage

The image to use for the inint container to perform the `chown` on the NFS mounts.

The default is `quay.io/mongodb/mongodb-enterprise-init-database-ubi:1.0.9"`

#### replicaSet.storage.single.size

The persistent storage that is assigned to each pod. The units suffix can be one of the following: E, P, T, G, M, K, Ei, Pi, Ti, Gi, Mi, Ki.

#### replicaSet.storage.single.storageClass

The name of the storage class that is used to create the persistentVolumeClaim for the data partition.

#### replicaSet.storage.multi.data.size

The persistent storage that is assigned to each pod for data storage. The units suffix can be one of the following: E, P, T, G, M, K, Ei, Pi, Ti, Gi, Mi, Ki.

#### replicaSet.storage.multi.data.storageClass

The name of the storage class that is used to create the persistentVolumeClaim for the journal partition.

### replicaSet.storage.multi.journal.size

The persistent storage that is assigned to each pod for journal storage. The units suffix can be one of the following: E, P, T, G, M, K, Ei, Pi, Ti, Gi, Mi, Ki.

### replicaSet.storage.multi.journal.storageClass

The name of the storage class that is used to create the persistentVolumeClaim for the log partition.

### replicaSet.storage.multi.logs.size

The persistent storage that is assigned to each pod for log storage. The units suffix can be one of the following: E, P, T, G, M, K, Ei, Pi, Ti, Gi, Mi, Ki.

### replicaSet.storage.multi.logs.storageClass

The name of the storage class that is used to create the persistentVolumeClaim.

### extAccess.enabled

A boolean to determine if external access, and therefore Split Horizon, is required/enabled.

### extAccess.exposeMethod

The service that will be used to provide access to the MognoDB replica set from external to Kubernetes. Choices are `NodePort` or `LoadBalancer`.

Kubernetes [documentation](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) should be consulted on the best method for the environment.

### extAccess.ports

An array of object (see following attributes) that describe the Horizon name, port, and clusterIP for each member of the replica set. One object is required per member.

### extAccess.ports[n].horizonName

The MongoDB horizon name for the selected pod.

### extAccess.ports[n].port

The port number for either the NodePort or the LoadBalancer for the selected pod.

### extAccess.ports[n].clusterIP

The clusterIP for the selected pod. Only required when `NodePort` is selected as the service.

### kmip.enabled

A boolean value to determine if KMIP is used to perform encryption at rest within the MongoDB deployments.

### kmip.host 

The FQDN if the KMIP device/service.

### kmip.port

The port number of the KMIP device/service, normally 5696.

## Sharded Cluster Specific SettingsThe following are settings required if a replica set is to be deployed.

To ensure a sharded cluster is deployed set the following:

```
replicaSet:
  enabled: false
sharding:
  enabled: true
```

### TLS X.509 Certificates for MongoDB Deployments _HIGHLY ENCOURAGED_

This requires AT LEAST six secrets. For each eash shard, config server replica set, and all the mongos instance there is one certificate for the client communications and one for cluster communications.

The secrets contain the X.509 key and certificate. One key/certificate pair is used for all members of the replica set/shard/mongos pool, therefore a Subject Alternate Name (SAN) entry must exist for each member of the replica set/shard/mongos. The SANs will be in the form of:

#### Shard Members

The SAN FQDN for each shard member is as follows:
**\<clusterName\>-\<X\>-<Y>.\<clusterName\>-svc.\<namespace\>.svc.cluster.local**

Where `<clusterName>` is the `clusterName` in the `values.yaml` for your deployment and `<X>` is the 0-based number of the shard and `<Y>` is the 0-based number of the shard member.

The certificate must include the name of FQDN external to Kubernetes as a Subject Alternate Name (SAN) if external access is required (`sharding.extAccess.enabled` set to `true`), plus an FQDN for each shard member for each domain set via `sharding.extAccess.externalDomains`.

The secrets must be named as follows:

**mdb-<clusterName\>-\<X\>-\<cert\>**

**mdb-<clusterName\>-\<X\>-\<clusterfile\>**

Where `<X>` is the shard number.

The two secrets for each shard can be created as follows:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret tls mdb-<clusterName>-<X>-cert \
  --cert=<path-to-cert> \
  --key=<path-to-key>

kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret tls mdb-<clusterName>-<X>-clusterfile \
  --cert=<path-to-cert> \
  --key=<path-to-key>
```

**REQUIRED** if `tls.enabled` is `true`.

#### Config Server Replica Set

A single X509 key and certificate is required for the Config Server Replica Set. These will be used to create two secrets: one for client communications and one for intra-replica set authentication. The FQDN of each replica set member must be in the certificate as a Subject Alternate Name (SAN).

The SAN FQDN for each shard member is as follows:

**\<clusterName\>-config-\<X\>.\<clusterName\>-svc.\<namespace\>.svc.cluster.local**

Where `<clusterName>` is the `clusterName` in the `values.yaml` for your deployment and `<X>` is the 0-based number of the replica set member.

The certificate must include the name of FQDN external to Kubernetes as a Subject Alternate Name (SAN) if external access is required (`sharding.extAccess.enabled` set to `true`), plus an FQDN for each config server replica set member for each domain set via `sharding.extAccess.externalDomains`.

The secrets must be named as follows:

**mdb-<clusterName\>-config-\<cert\>**

**mdb-<clusterName\>-config-\<clusterfile\>**

The two secrets for the config server replica set can be created as follows:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret tls mdb-<clusterName>-config-cert \
  --cert=<path-to-cert> \
  --key=<path-to-key>

kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret tls mdb-<clusterName>-config-clusterfile \
  --cert=<path-to-cert> \
  --key=<path-to-key>
```

**REQUIRED** if `tls.enabled` is `true`.

#### Mongos

A single X509 key and certificate is required for all the mongos instances in the cluster. These will be used to create two secrets: one for client communications and one for intra-replica set authentication. The FQDN of each mongos instance must be in the certificate as a Subject Alternate Name (SAN).

Two secrets are required for the collective of mongos instances in the cluster (not one per mongos).

The SAN FQDN for each of the mongoses is as follows:

**\<clusterName\>-svc-\<X\>.\<clusterName\>-svc.\<namespace\>.svc.cluster.local**

Where `<clusterName>` is the `clusterName` in the `values.yaml` for your deployment and `<X>` is the 0-based number of the mongos instance.

The certificate must include the name of FQDN external to Kubernetes as a Subject Alternate Name (SAN) if external access is required (`sharding.extAccess.enabled` set to `true`), plus an FQDN for each mongos for each domain set via `sharding.extAccess.externalDomains`.

The secrets must be named as follows:

**mdb-<clusterName\>-svc-\<cert\>**

**mdb-<clusterName\>-svc-\<clusterfile\>**

The two secrets for the config server replica set can be created as follows:

```shell
kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret tls mdb-<clusterName>-config-cert \
  --cert=<path-to-cert> \
  --key=<path-to-key>

kubectl --kubeconfig=<CONFIG_FILE> -n <NAMESPACE> create secret tls mdb-<clusterName>-config-clusterfile \
  --cert=<path-to-cert> \
  --key=<path-to-key>
```

**REQUIRED** if `tls.enabled` is `true`.

## Predeployment Checklist

Ensure all the following as satisfied before attempoting to deploy:

- [ ] Create a new directory under the `charts/values` directory for the environment
- [ ] Copy the example `values.yaml` file from the `examples` directory to the new directory
- [ ] Ops Manager API Access Token created including the CIDR range of the Kubernetes Operator for the API Access List
- [ ] Ops Manager API Access Token secret created
- [ ] Ops Manager CA Certificate secret created
- [ ] MongoDB deployment CA certificate configmap created (recommended)
- [ ] MongoDB deployment TLS certificate secret created (recommended)
- [ ] Password secret for the first user created
- [ ] Configure external access (horizons) if required
- [ ] Configure LDAP access if required
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