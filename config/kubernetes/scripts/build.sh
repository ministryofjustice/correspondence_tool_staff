#!/bin/sh

function _build() {
  usage="build -- build, tag and push image to ecr
  Usage: build"

  region='eu-west-2'
  context='live-1'
  aws_profile='ecr-live1'

  team_name=correspondence
  repo_name=correspondence_tool_staff
  docker_endpoint=754256621582.dkr.ecr.eu-west-2.amazonaws.com
  docker_registry=${docker_endpoint}/${team_name}/${repo_name}

  component=app
  current_branch=$(git branch | grep \* | cut -d ' ' -f2)
  current_version=$(git rev-parse $current_branch)

  docker_build_tag=${component}-${current_version}
  docker_registry_tag=${docker_registry}:${docker_build_tag}

  printf "\e[33m------------------------------------------------------------------------\e[0m\n"
  printf "\e[33mBuild tag: $docker_build_tag\e[0m\n"
  printf "\e[33mBranch: $current_branch\e[0m\n"
  printf "\e[33mRegistry tag: $docker_registry_tag\e[0m\n"
  printf "\e[33m------------------------------------------------------------------------\e[0m\n"
  printf '\e[33mDocker login to registry (ECR)...\e[0m\n'
  $(aws ecr --profile "$aws_profile" get-login --no-include-email --region "$region")

  printf '\e[33mBuilding app container image locally...\e[0m\n'
  docker build \
          --build-arg VERSION_NUMBER=$docker_registry_tag \
          --build-arg BUILD_DATE=$(date +%Y-%m-%dT%H:%M:%S%z) \
          --build-arg COMMIT_ID=$current_version \
          --build-arg BUILD_TAG=$docker_build_tag \
          --pull \
          --tag ${docker_registry_tag} \
          --file ../../../Dockerfile .

  printf '\e[33mPushing app container image to ECR...\e[0m\n'
  docker push ${docker_registry_tag}
  printf '\e[33mPushed app container image to ECR...\e[0m\n'

  # tag as latest for branch too
  case $current_branch in
    master)
      latest_tag=${docker_registry}:${component}-latest
      ;;
    *)
      latest_tag=${docker_registry}:${component}-${current_branch}-latest
      ;;
  esac

  docker tag $docker_registry_tag $latest_tag
  docker push $latest_tag
  printf "\e[33mAlso tagged as ${latest_tag}...\e[0m\n"

}

_build $@
