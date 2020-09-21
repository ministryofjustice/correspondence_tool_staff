#!/bin/sh

# exit when any command fails
set -e

p() {
  printf "\e[33m$1\e[0m\n"
}

function _build() {

  # 1. Define variables for use in the script
  team_name=correspondence
  ecr_repo_name=track-a-query-ecr
  component=track-a-query

  region='eu-west-2'
  context='live-1'
  aws_profile='ecr-live-1'

  git_remote_url="https://github.com/ministryofjustice/correspondence_tool_staff.git";
  docker_endpoint=754256621582.dkr.ecr.eu-west-2.amazonaws.com
  docker_registry=${docker_endpoint}/${team_name}/${ecr_repo_name}

  current_branch=$(git branch | grep \* | cut -d ' ' -f2)
  current_version=$(git rev-parse $current_branch)
  short_version=$(git rev-parse --short $current_branch)

  docker_build_tag=cts-${current_branch}-${short_version}
  export BUILD_TAG=${docker_build_tag}
 

 

  # 8. Display the tag to use for deployment
  p "Pushed to ${docker_registry_tag}"
  p "Image created with unique tag: \e[32m$docker_build_tag\e[0m\n"

}

_build $@
