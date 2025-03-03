#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

SCRIPT_ROOT=$(dirname ${BASH_SOURCE})/..
CODEGEN_PKG=${CODEGEN_PKG:-$(cd ${SCRIPT_ROOT}; ls -d -1 ./vendor/k8s.io/kube-openapi 2>/dev/null || echo ../../../k8s.io/kube-openapi)}

GOFLAGS="" go install -mod=vendor ./${CODEGEN_PKG}/cmd/openapi-gen

function codegen::join() { local IFS="$1"; shift; echo "$*"; }

ORIGIN_PREFIX="github.com/openshift/openshift-apiserver/"

KUBE_INPUT_DIRS=(
  $(
    grep --color=never -rl '+k8s:openapi-gen=' vendor/k8s.io | \
    xargs -n1 dirname | \
    sed "s,^vendor/,," | \
    sort -u | \
    sed '/^k8s\.io\/kubernetes\/build\/root$/d' | \
    sed '/^k8s\.io\/kubernetes$/d' | \
    sed '/^k8s\.io\/kubernetes\/staging$/d' | \
    sed 's,k8s\.io/kubernetes/staging/src/,,'
  )
)
ORIGIN_INPUT_DIRS=(
  $(
    grep --color=never -rl '+k8s:openapi-gen=' vendor/github.com/openshift/api | \
    xargs -n1 dirname | \
    sed "s,^vendor/,," | \
    sort -u
  )
)
APIEXTENSIONS_INPUT_DIRS=(
    k8s.io/apimachinery/pkg/apis/meta/v1
    k8s.io/api/autoscaling/v1
)

function join { local IFS="$1"; shift; echo "$*"; }

echo "Generating origin openapi"
${GOPATH}/bin/openapi-gen \
  --output-file zz_generated.openapi.go \
  --go-header-file ${SCRIPT_ROOT}/hack/boilerplate.txt \
  --output-dir="${GOPATH}/src" \
  "${KUBE_INPUT_DIRS[@]}" "${ORIGIN_INPUT_DIRS[@]}" \
  --output-pkg "${ORIGIN_PREFIX}/pkg/openapi" \
  --report-filename "${SCRIPT_ROOT}/hack/openapi-violation.list" \
  "$@"
