# Change Log

# 2.0.0

* Major change - includes breaking changes
* Can now manage sharded clusters
* The format for replica set has changed in the `values.yaml` file
* Replica sets and sharded clusters are within their own objects within the `values.yaml` file
* Targeted at 1.18.x series of the MongoDB Enterprise Kubernetes Operator

# 1.2.0

* Introduced option to use NFS for PV, which requires a further init container to configure the permissions. See the README for further details
