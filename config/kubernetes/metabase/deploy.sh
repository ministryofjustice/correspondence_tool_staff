#!/bin/sh

# exit when any command fails
set -e

function _deploy() {

  # Apply non-image specific config
  kubectl apply \
    -f ./deployment.yaml \
    -f ./service.yaml \
    -f ./ingress.yaml \
    -n track-a-query-metabase

}

_deploy $@
