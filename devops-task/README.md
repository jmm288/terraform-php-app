# Task Delivery
* Please don't fork, branch or create a pull request within this repository. 
* Clone it and do your work there.
* When the task is ready, **Email** your zipped solution back to us (Only first submit count unless otherwise directed).

# Devops Test Task
Thank you for applying to Mode Transportation! We'd like to see how you can build out infrastructure and CI/CD.

## Hello World PHP App
Provided in `src` is a "hello world" PHP app with 2 files.

## Part 1: Infrastructure
Your goal is to set up this app so that it runs on AWS infrastructure. 
You can choose any appropriate AWS technology. Please utilize the AWS Free Tier if you do not have a personal AWS account already. https://aws.amazon.com/free

Your output for this step should be a **single or very few commands** that fully initializes and configures all required infrastructure.
Please **update** this **README** file as part of the solution to **document the execution procedure, assumptions, environment setups, considerations**, etc.

#### The code will be run on a blank AWS account with zero existing resources where you will need to provision everything as part of your infrastructure stack.

### Part 1 Solution Below ###

I made a terraform script that uses a few simple variables, outputs and provisions an ec2-instance.

Execution Procedure:
Verify Assumptions and ENV Setup are complete.
1. In the provision_infra directory run: "terraform init && terraform fmt && terraform validate && terraform apply"
2. After the infrastructure comes up, ssh into the instance and add ECS instance to ECS cluster via this command:
`curl --proto "https" -o "/tmp/ecs-anywhere-install.sh" "https://amazon-ecs-agent.s3.amazonaws.com/ecs-anywhere-install-latest.sh" && bash /tmp/ecs-anywhere-install.sh --region "us-west-2" --cluster "my-php-app-cluster" --activation-id "1f4a002a-87a8-4643-9fdf-27e8dea77f5f" --activation-code "5IUPxZlq9759V/Fkp9Ma"`

Assumptions:
1. Aws-user must be created with corresponding AWS Access keys
2. Aws-user must have ec2/ecs/ecr permissions. 

ENV Setup:
1. AWS Credentials must be exported to the ENV
2. AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY must be set in the GitHub Action repository secrets to allow GitHub Actions to push/pull.

Considerations:
1. I wanted to get the ECS Cluster to auto-recognize the ECS Instance I was creating. I couldn't get it to work in the amount of time I had though, I just went ahead and manually connected the instance to the cluster.

### Part 1 Solution Above ###

## Part 2: CI/CD
Your goal for this step is to set up an automated build and deployment pipeline. Please use a SaaS provider that has
the ability to be configured entirely by file. GitHub Actions, GitLab, CircleCI, TravisCI, or any other provider with a free tier.

The pipeline steps should be:

1. Check out the repository
2. Install any dependencies
3. Build the application
4. Deploy the code update to AWS

For extra credit, you can come up with a process to display the current version number (defined as the build number)
as an HTTP header or within the web application.

Your deliverable here should be a configuration file that we could run. You can also share access to the SaaS to show us
your own working pipeline.

### Part 2 Solution Below ###

## Github Actions yaml file ##

name: GitHub Actions PHP Mode Transportation
env:
  AWS_REGION: us-west-2                       # set this to your preferred AWS region, e.g. us-west-1
  ECR_REPOSITORY: php-app                     # set this to your Amazon ECR repository name
  ECS_SERVICE: php-app-worker                 # set this to your Amazon ECS service name
  ECS_CLUSTER: my-php-app-cluster             # set this to your Amazon ECS cluster name
  ECS_TASK_DEFINITION: devops-task/src/provision_infra/task-definition.json # set this to the path to your Amazon ECS task definition
  CONTAINER_NAME: php-app                     # set this to the name of the container in the containerDefinitions section of your task definition
  REPOSITORY_URL: 435901930649.dkr.ecr.us-west-2.amazonaws.com/$ECR_REPOSITORY
  
on: [push]
jobs:
  deploy:
    name: Deploy Php App
    runs-on: ubuntu-18.04
    environment: production

    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Build, tag, and push image to Amazon ECR
      id: build-image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build . --file devops-task/src/Dockerfile -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker build . --file devops-task/src/Dockerfile -t $ECR_REGISTRY/$ECR_REPOSITORY:latest
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
        echo "::set-output name=image::$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
    - name: Fill in the new image ID in the Amazon ECS task definition
      id: task-def
      uses: aws-actions/amazon-ecs-render-task-definition@v1
      with:
        task-definition: ${{ env.ECS_TASK_DEFINITION }}
        container-name: ${{ env.CONTAINER_NAME }}
        image: ${{ steps.build-image.outputs.image }}

    - name: Deploy Amazon ECS task definition
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: ${{ steps.task-def.outputs.task-definition }}
        service: ${{ env.ECS_SERVICE }}
        cluster: ${{ env.ECS_CLUSTER }}
        wait-for-service-stability: true`

## ECS Task Definition file ##

`{
    "taskDefinitionArn": "arn:aws:ecs:us-west-2:435901930649:task-definition/php-app:4",
    "containerDefinitions": [
        {
            "name": "php-app",
            "image": "435901930649.dkr.ecr.us-west-2.amazonaws.com/php-app:latest",
            "cpu": 2,
            "memory": 300,
            "portMappings": [
                {
                    "containerPort": 80,
                    "hostPort": 8000,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "environment": [],
            "mountPoints": [],
            "volumesFrom": []
        }
    ],
    "family": "php-app",
    "revision": 4,
    "volumes": [],
    "status": "ACTIVE",
    "requiresAttributes": [
        {
            "name": "com.amazonaws.ecs.capability.ecr-auth"
        }
    ],
    "placementConstraints": [],
    "compatibilities": [
        "EXTERNAL",
        "EC2"
    ],
    "registeredAt": "2022-03-20T22:08:46.460000-04:00",
    "registeredBy": "arn:aws:iam::435901930649:user/jbarton"
}`
### Part 2 Solution Above ###

Good luck!
