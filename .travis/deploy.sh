#! /usr/bin/env bash

set -e

function message() {
    echo
    echo -----------------------------------
    echo "$@"
    echo -----------------------------------
    echo
}

ENVIRONMENT=$1
REGION=$2

if [ -z "$ENVIRONMENT" ]; then
    echo 'You must specifiy an envionrment (bash deploy.sh <ENVIRONMENT>).'
    echo 'Allowed values are "staging" or "prod"'
    exit 1
fi


ECR_REPO="$AWSACCT.dkr.ecr.us-east-1.amazonaws.com/govpoll-$ENVIRONMENT"
SERVICE="govpoll-$ENVIRONMENT"

message LOGGING INTO ECR
$(aws ecr get-login --no-include-email --endpoint https://ecr.us-east-1.amazonaws.com --region us-east-1)

message BUILDING DOCKER IMAGE
docker build --tag "${ECR_REPO}:latest" .

message PUSHING DOCKER IMAGE
docker push "${ECR_REPO}:latest"

message DEPLOYING SERVICE
aws ecs update-service --cluster govpoll-cluster-$ENVIRONMENT --service govpoll-etl-service-$ENVIRONMENT --desired-count 0 --region $REGION
sleep 30
aws ecs update-service --cluster govpoll-cluster-$ENVIRONMENT --service govpoll-etl-service-$ENVIRONMENT --force-new-deployment --desired-count 1 --endpoint https://ecs.$REGION.amazonaws.com --region $REGION
aws ecs update-service --cluster govpoll-cluster-$ENVIRONMENT --service govpoll-api-service-$ENVIRONMENT --force-new-deployment --endpoint https://ecs.$REGION.amazonaws.com --region  $REGION
