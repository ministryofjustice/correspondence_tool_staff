#!/bin/sh

# exit when any command fails
set -e

p() {
  printf "\e[33m$1\e[0m\n"
}

function _deploy() {

  # Define variables for use in the script
  team_name=correspondence
  ecr_repo_name=track-a-query-ecr
  component=track-a-query

  context='live-1'

  docker_endpoint=754256621582.dkr.ecr.eu-west-2.amazonaws.com
  docker_registry=${docker_endpoint}/${team_name}/${ecr_repo_name}

  usage="deploy -- deploy image from ECR to an environment
  Usage: ./deploy.sh image-tag environment
  Where:
    environment - one of development|staging|demo|qa|production
    image-tag   - any valid ECR image tag for app generated by build script
  Prerequisites:
    Build an image to deploy using build.sh in a checked out
    copy of the head of the branch you want to deploy. Supply the
    resulting image tag to this deploy script.
  Example:
    # build the app to get an image tag
    ./build.sh
    ...many lines of output...
    Image created with tag: track-a-query-cloud-deploy-6bece953

    # deploy image-tag to development
    ./deploy.sh track-a-query-CT-1234-cloud-deploy-6bece953 development

    # deploy latest image of main to production
    ./deploy.sh track-a-query-main-6bece953 production
    "

  # Ensure the script is called with two or three arguments
  if [ $# -lt 2 ] || [ $# -gt 3 ]
  then
    echo "$usage"
    return 1
  fi
  
  if [[ "$3" == "circleci" ]]
  then
    image_tag=$1
  else  
    # Ensure that the first argument is a reasonable image name
    if [[ "$1" =~ ^cts- ]]
    then
      image_tag=$1
    else
      p "\e[31mFatal error: Image tag not recognised: $1\e[0m"
      p "\e[31mPlease supply an image tag generated by the build script as the first argument\e[0m\n"
      echo "$usage"
      return 1
    fi

  fi
  # Ensure that the second argument is a valid stage
  case "$2" in
    development | staging | demo | qa | production)
      environment=$2
      ;;
    *)
      p "\e[31mFatal error: deployment environment not recognised: $2\e[0m"
      p "\e[31mEnvironment must be one of development | staging | demo | qa | production\e[0m\n"
      echo "$usage"
      return 1
      ;;
  esac

  # Ensure that the git-crypt secrets are unlocked ready for deployment
  if grep -rq "\x0GITCRYPT" config/kubernetes/$environment/secrets.yaml; then
    p "\e[31mFatal error: repository is locked with git-crypt\e[0m"
    p "\e[31mUnlock using 'git-crypt unlock'\e[0m\n"
    return 1
  fi

  # Confirm what's going to happen and ask for confirmation
  docker_image_tag=${docker_registry}:${image_tag}

  namespace=$component-${environment}
  p "--------------------------------------------------"
  p "Deploying Track a Query to kubernetes cluster: $context"
  p "Environment: \e[32m$environment\e[0m"
  p "Docker image: \e[32m$image_tag\e[0m"
  p "Target namespace: \e[32m$namespace\e[0m"
  p "--------------------------------------------------"

  if [[ "$3" != "circleci" ]]
  then
    if [[ $environment == "production" ]]
    then
      read -p "Do you wish to deploy this image to production? (Enter 'deploy' to continue): " confirmation_message
      if [[ $confirmation_message == "deploy" ]]
      then
        p "Deploying app to production..."
      else
        return 0
      fi
    else
      read -p "Do you wish to deploy this image to $environment? (Enter Y to continue): " confirmation_message
      if [[ $confirmation_message =~ ^[Yy]$ ]]
      then
        p "Deploying app to $environment..."
      else
        return 0
      fi
    fi
  fi

  # Set context for following operations
  # kubectl config set-context ${context} --namespace=$namespace
  # kubectl config use-context ${context}

  # Apply config map updates
  kubectl apply \
    -f config/kubernetes/${environment}/configmap.yaml -n $namespace

  # Apply image specific config
  kubectl set image -f config/kubernetes/${environment}/deployment.yaml \
          webapp=${docker_image_tag} \
          uploads=${docker_image_tag} \
          quickjobs=${docker_image_tag} --local --output yaml | kubectl apply -n $namespace -f -

  kubectl set image -f config/kubernetes/${environment}/deployment_sidekiq.yaml \
          jobs=${docker_image_tag} --local --output yaml | kubectl apply -n $namespace -f -

  # Apply non-image specific config
  kubectl apply \
    -f config/kubernetes/${environment}/service.yaml \
    -f config/kubernetes/${environment}/ingress.yaml \
    -f config/kubernetes/${environment}/secrets.yaml \
    -n $namespace

  if [ $environment == "production" ]
  then
    kubectl apply -f config/kubernetes/${environment}/cronjob-delete-old-ecr-images.yaml -n $namespace
    kubectl apply -f config/kubernetes/${environment}/cronjob-anonymizer.yaml -n $namespace
  fi

  # if [ $environment == "qa" ]
  # then
  #   kubectl apply -f config/kubernetes/${environment}/cronjob-restore-anonymised-db.yaml -n $namespace
  #   kubectl apply -f config/kubernetes/${environment}/cronjob-update-search-index.yaml -n $namespace
  # fi

  # Deploy to Live cluster
  if [ $environment == "staging" ] || [ $environment == "development" ] || [ $environment == "qa" ]
  then
    p "--------------------------------------------------"
    p "Deploying Track a query to kubernetes cluster: Live"
    p "Environment: \e[32m$environment\e[0m"
    p "Docker image: \e[32m$image_tag\e[0m"
    p "Target namespace: \e[32m$namespace\e[0m"
    p "--------------------------------------------------"

    if [[ "$3" == "circleci" ]]
    then
      # Authenticate to live cluster
      p "Authenticating to live..."
      echo -n $KUBE_ENV_LIVE_CA_CERT | base64 -d > ./live_ca.crt
      kubectl config set-cluster $KUBE_ENV_LIVE_CLUSTER_NAME --certificate-authority=./live_ca.crt --server=https://$KUBE_ENV_LIVE_CLUSTER_NAME
      
      if [[ $environment == "development" ]]
      then
        live_token=$KUBE_ENV_LIVE_DEVELOPMENT_TOKEN
      fi

      if [[ $environment == "staging" ]]
      then
        live_token=$KUBE_ENV_LIVE_STAGING_TOKEN
      fi
      
      if [[ $environment == "qa" ]]
      then
        live_token=$KUBE_ENV_LIVE_QA_TOKEN
      fi

      kubectl config set-credentials circleci --token=$live_token
      kubectl config set-context $KUBE_ENV_LIVE_CLUSTER_NAME --cluster=$KUBE_ENV_LIVE_CLUSTER_NAME --user=circleci --namespace=$namespace
      kubectl config use-context $KUBE_ENV_LIVE_CLUSTER_NAME
      kubectl config current-context
      kubectl --namespace=$namespace get pods
    fi

    #deploy to live cluster
    p "Authenticated, deploying to live..."
  fi

  # Apply config map updates
  kubectl apply \
    -f config/kubernetes/${environment}/configmap.yaml -n $namespace

  # Apply image specific config
  kubectl set image -f config/kubernetes/${environment}/deployment.yaml \
          webapp=${docker_image_tag} \
          uploads=${docker_image_tag} \
          quickjobs=${docker_image_tag} --local --output yaml | kubectl apply -n $namespace -f -

  kubectl set image -f config/kubernetes/${environment}/deployment_sidekiq.yaml \
          jobs=${docker_image_tag} --local --output yaml | kubectl apply -n $namespace -f -

  # Apply non-image specific config
  kubectl apply \
    -f config/kubernetes/${environment}/service.yaml \
    -f config/kubernetes/${environment}/ingress-live.yaml \
    -f config/kubernetes/${environment}/secrets.yaml \
    -n $namespace

  if [ $environment == "production" ]
  then
    kubectl apply -f config/kubernetes/${environment}/cronjob-delete-old-ecr-images.yaml -n $namespace
    kubectl apply -f config/kubernetes/${environment}/cronjob-anonymizer.yaml -n $namespace
  fi

  # if [ $environment == "qa" ]
  # then
  #   kubectl apply -f config/kubernetes/${environment}/cronjob-restore-anonymised-db.yaml -n $namespace
  #   kubectl apply -f config/kubernetes/${environment}/cronjob-update-search-index.yaml -n $namespace
  # fi

}

_deploy $@
