# Change Log

# 3.0.0

* Major change - includes breaking changes
* Targeted at MongoDB Controllers for Kubernetes (MCK) 1.11.0, which replaces the MongoDB Enterprise Kubernetes Operator (MEKO). See the MongoDB [migration guide](https://www.mongodb.com/docs/kubernetes/current/tutorial/migrate-to-mck/)
* The `operator` value has been removed, the charts now always render the MCK container names
* `spec.exposedExternally`, removed by the operator, has been replaced with `spec.externalAccess`, configured through the new `externalAccess` value
* The `mongodb.com/v1.architecture` annotation is now always set, and defaults to `static` via the `staticPods` value
* Security and backup settings are now applied to sharded clusters as well as replica sets
* Values are checked when the charts are rendered, and `backup` and `externalAccess` have been added to `values.schema.json`
* `imagePullSecrets` is now honoured for replica sets, which previously hardcoded `regcred`
* `helmfile.yaml` now installs the MCK operator alongside the deployment
* Added unit tests, CRD validation and a GitHub Actions workflow
* Removed the NFS documentation, which described a 1.2.0 feature that no template has implemented since 2.0.0

# 2.0.0

* Major change - includes breaking changes
* Can now manage sharded clusters
* The format for replica set has changed in the `values.yaml` file
* Replica sets and sharded clusters are within their own objects within the `values.yaml` file
* Targeted at 1.18.x series of the MongoDB Enterprise Kubernetes Operator

# 1.2.0

* Introduced option to use NFS for PV, which requires a further init container to configure the permissions. See the README for further details
