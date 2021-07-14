#!/bin/bash
set -euo pipefail

unset KUBERNETES_SERVICE_HOST
unset KUBERNETES_SERVICE_PORT

CLUSTER="$(ni get -p {.cluster.name})"
CLUSTER="${CLUSTER:-default}"
KUBECONFIG="/workspace/${CLUSTER}/kubeconfig"
KUBECTL_ARGS=( "--kubeconfig=${KUBECONFIG}" )

ni cluster config

NS="$(ni get -p {.namespace})"
[ -n "${NS}" ] && KUBECTL_ARGS+=( "--namespace=${NS}" )

PRUNE="$( ni get | jq -r 'try .prune.labelSelectors | select(length > 0) | to_entries | map("\( .key )=\( .value )") | join(",")' )"
[ -n "${PRUNE}" ] && KUBECTL_ARGS+=( "--prune" "--selector=${PRUNE}" )

WORKSPACE_PATH="$(ni get -p {.path})"

GIT="$(ni get -p {.git})"
if [ -n "${GIT}" ]; then
    ni git clone
    NAME="$(ni get -p {.git.name})"
    WORKSPACE_PATH="/workspace/${NAME}/${WORKSPACE_PATH}"
fi

set -x
kustomize build "${WORKSPACE_PATH}" | kubectl apply "${KUBECTL_ARGS[@]}" -f -
