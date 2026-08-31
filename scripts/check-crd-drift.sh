#!/usr/bin/env bash
# Render every example and validate the result against the CRDs of a given MCK
# release. This is what catches a field being deprecated or removed upstream,
# which `helm lint` cannot see.
#
# Requires: helm, kubeconform, python3 (with PyYAML), curl.
#
#   MCK_VERSION=1.11.0 ./scripts/check-crd-drift.sh
set -euo pipefail

MCK_VERSION="${MCK_VERSION:-$(awk '/^appVersion:/ {gsub(/"/,"",$2); print $2}' charts/Chart.yaml)}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "==> Validating against MCK ${MCK_VERSION}"

curl -sfL -o "${WORKDIR}/crds.yaml" \
  "https://raw.githubusercontent.com/mongodb/mongodb-kubernetes/${MCK_VERSION}/public/crds.yaml"

# Convert each CRD into a JSON schema laid out the way kubeconform expects.
python3 - "${WORKDIR}/crds.yaml" "${WORKDIR}/schemas" <<'PY'
import json, os, sys, yaml

crds, outdir = sys.argv[1], sys.argv[2]
os.makedirs(outdir, exist_ok=True)
for doc in yaml.safe_load_all(open(crds)):
    if not doc or doc.get("kind") != "CustomResourceDefinition":
        continue
    kind = doc["spec"]["names"]["kind"].lower()
    for version in doc["spec"]["versions"]:
        schema = version.get("schema", {}).get("openAPIV3Schema")
        if not schema:
            continue
        with open(os.path.join(outdir, f"{kind}-{doc['spec']['group'].split('.')[0]}-{version['name']}.json"), "w") as fh:
            json.dump(schema, fh)
PY

status=0
for values in "${REPO_ROOT}"/examples/*/values.yaml; do
  echo "--> $(basename "$(dirname "$values")")"
  helm template drift "${REPO_ROOT}/charts" -f "$values" \
    | kubeconform -strict -summary \
        -schema-location default \
        -schema-location "${WORKDIR}/schemas/{{ .ResourceKind }}-{{ .Group }}-{{ .ResourceAPIVersion }}.json" \
    || status=1
done

exit "$status"
