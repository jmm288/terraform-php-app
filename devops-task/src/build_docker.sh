
#!/usr/bin/env bash

VERSION=${1:-0.0.0}
DOCKERFILE_LOC=${2:-./Dockerfile}
PROJECT_NAME=${3:-php_app}
REGISTRY_NAME=${4:-435901930649.dkr.ecr.us-east-1.amazonaws.com}

DOCKER_BUILD=$REGISTRY_NAME/$PROJECT_NAME:$VERSION
DOCKER_LATEST=$REGISTRY_NAME/$PROJECT_NAME:latest

echo "Running as"
whoami

echo "Moving Dockerfile"
echo $DOCKERFILE_LOC
cp $DOCKERFILE_LOC Dockerfile

echo "Building and Pushing docker image"
echo $DOCKER_BUILD
docker build . -t php_app
#docker push $DOCKER_BUILD
