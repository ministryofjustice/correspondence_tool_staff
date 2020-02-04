#!/bin/sh
function _circleci_deploy() {
  usage="deploy -- deploy image from current commit to an environment
  Usage: $0 environment
  Where:
    environment [development|staging|demo|qa|production]
  Example:
    # deploy image for current circleCI commit to development
    deploy.sh development
    "

  if [[ -z "${ECR_ENDPOINT}" ]] || \
      [[ -z "${GIT_CRYPT_KEY}" ]] || \
      [[ -z "${AWS_DEFAULT_REGION}" ]] || \
      [[ -z "${GITHUB_TEAM_NAME_SLUG}" ]] || \
      [[ -z "${REPO_NAME}" ]] || \
      [[ -z "${CIRCLE_SHA1}" ]]
  then
    echo "Missing environment vars: only run this via CircleCI with all relevant environment variables"
    return 1
  fi

  if [[ $# -gt 1 ]]
  then
    echo "$usage"
    return 1
  fi

  # Cloud platforms circle ci solution does not handle hyphenated names
  case "$1" in
    development|staging|demo|qa|production)
      environment=$1
      cp_context=$environment
      ;;
    *)
      echo "$usage"
      return 1
      ;;
  esac

  # Cloud platform required setup
  $(aws ecr get-login --region ${AWS_DEFAULT_REGION} --no-include-email)
  setup-kube-auth
  kubectl config use-context ${cp_context}

  echo "${GIT_CRYPT_KEY}" | base64 -d > git-crypt.key
  git-crypt unlock git-crypt.key

  # apply
  printf "\e[33m--------------------------------------------------\e[0m\n"
  printf "\e[33mEnvironment: $environment\e[0m\n"
  printf "\e[33mCommit: $CIRCLE_SHA1\e[0m\n"
  printf "\e[33mBranch: $CIRCLE_BRANCH\e[0m\n"
  printf "\e[33m--------------------------------------------------\e[0m\n"

  #docker_image_tag=${ECR_ENDPOINT}/${GITHUB_TEAM_NAME_SLUG}/${REPO_NAME}:app-${CIRCLE_SHA1}
  docker_image_tag="754256621582.dkr.ecr.eu-west-2.amazonaws.com/correspondence/track-a-query-ecr:latest"

  # Apply image specific config
  kubectl apply -f config/kubernetes/${environment}/secrets.yaml
  kubectl set image -f config/kubernetes/${environment}/deployment.yaml \
          webapp=${docker_image_tag} \
          uploads=${docker_image_tag} \
          jobs=${docker_image_tag} --local --output yaml  --local -o yaml | kubectl apply -f -

  # Apply non-image specific config
  kubectl apply \
    -f config/kubernetes/${environment}/service.yaml \
    -f config/kubernetes/${environment}/ingress.yaml \

  # Namespace specific actions e.g. clean ecr, etc
  # if [[ ${environment} == 'development' ]]; then
  # fi

  kubectl annotate deployments/track-a-query kubernetes.io/change-cause="$(date +%Y-%m-%dT%H:%M:%S%z) - deploying: $docker_image_tag via CircleCI"
}

_circleci_deploy $@
