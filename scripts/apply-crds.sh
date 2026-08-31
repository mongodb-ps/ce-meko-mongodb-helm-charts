#!/usr/bin/env bash
# Apply the MCK CRDs. Helm installs the CRDs shipped in the operator chart's
# crds/ directory on first install only, and never upgrades them, so this must
# be run by hand whenever the MCK version changes.
set -euo pipefail

MCK_VERSION="${MCK_VERSION:-1.11.0}"

kubectl apply --server-side \
  -f "https://raw.githubusercontent.com/mongodb/mongodb-kubernetes/${MCK_VERSION}/public/crds.yaml"
