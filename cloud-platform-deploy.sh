#!/bin/bash

echo '----------------------------' &&  \
echo 'DEPLOYING: ' $1 && \
echo 'AWS Login: ' && \
$(aws ecr get-login --no-include-email --region eu-west-2 --profile ecr-live-1) && \
echo 'Begin environment upload' && \
echo '----------------------------' && \
echo '' && \
echo 'Build image' && \
docker build -t correspondence/track-a-query-ecr . && \
docker tag correspondence/track-a-query-ecr:latest 754256621582.dkr.ecr.eu-west-2.amazonaws.com/correspondence/track-a-query-ecr:latest && \
docker push 754256621582.dkr.ecr.eu-west-2.amazonaws.com/correspondence/track-a-query-ecr:latest && \
#kubectl delete --filename config/kubernetes/$1 --namespace track-a-query-$1 && \
kubectl apply --filename config/kubernetes/$1 --namespace track-a-query-$1 && \
kubectl get pods --namespace track-a-query-$1 && \
echo 'Completed upload' && \
echo '----------------------------' && \
echo '';
