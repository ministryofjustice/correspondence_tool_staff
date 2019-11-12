#!/bin/sh

function _deploy() {
  usage="deploy -- deploy image from current commit to an environment
  Usage: /config/kubernetes/deploy environment [image-tag]
  Where:
    environment [development|staging|qa]
    [image_tag] any valid ECR image tag for app
  Example:
    # deploy image for current commit to development
    deploy.sh development

    # deploy latest image of master to development
    deploy.sh development latest

    # deploy latest branch image to development
    deploy.sh development <branch-name>-latest

    # deploy specific image (based on commit sha)
    deploy.sh development <commit-sha>
    "

  if [ $# -gt 2 ]
  then
    echo "$usage"
    return 0
  fi

  case "$1" in
    development | staging | qa | demo | production)
      environment=$1
      ;;
    *)
      echo "$usage"
      return 0
      ;;
  esac

  if [ -z "$2" ]
  then
    current_branch=$(git branch | grep \* | cut -d ' ' -f2)
    current_version=$(git rev-parse $current_branch)
  else
    current_version=$2
  fi

  context='live-1'
  component=app

  docker_registry=754256621582.dkr.ecr.eu-west-2.amazonaws.com/correspondence/correspondence_tool_staff
  docker_image_tag=${docker_registry}:${component}-${current_version}

  kubectl config set-context ${context} --namespace=track-a-query-${environment}
  kubectl config use-context ${context}

  printf "\e[33m--------------------------------------------------\e[0m\n"
  printf "\e[33mContext: $context\e[0m\n"
  printf "\e[33mEnvironment: $environment\e[0m\n"
  printf "\e[33mDocker image: $docker_image_tag\e[0m\n"
  printf "\e[33m--------------------------------------------------\e[0m\n"

  kubectl delete --filename ../$environment --namespace track-a-query-$environment && \
  kubectl create --filename ../$1 --namespace track-a-query-$environment && \
  kubectl get pods --namespace track-a-query-$environment
}

_deploy $@
