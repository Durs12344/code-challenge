# Hello World
Hello World Go http webap and Terraform ECS infrastructure config.

## Pre-requisite
- Install [terraform v1.5.7](https://www.terraform.io/downloads.html)
- Setup your local shell enviornment's [aws cli credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) with the `default` profile name.
- [Docker](https://docs.docker.com/get-docker/) installed locally 

## Infrastructure Setup

1. Create the `remote_state` terraform backend. This will create an S3 bucket that will be used as the terraform remote state bucket.

```bash
cd infra/modules/remote_state; terraform init; terraform apply
```

2. Return to the root directory `infra` and then deploy the `ecs` infrastructure to host the application.

```bash
cd ../../; terraform init; terraform apply
```

This will return:
* The VPC ID where the resources are being deployed
* The Subnet Cidr Blocks that will be used
* The Hello World app web server loadbalancer endpoint to access app.
* ECR url to push docker images

## App Deployment

1. Change directories to the app directory then build the Docker image for the hello_go_http app and tag it with the release version and ecr_repo_url. 

```bash
cd ../hello_go_http; docker build -t ${ecr_repo_url}:${release_version} .
```

2. Get the Docker login for the ECR repo and login

```bash
aws ecr get-login-password --region ${regin} | docker login --username AWS --password-stdin ${ecr_repo_url}
```

3. Push the docker image to ECR

```bash
docker push ${ecr_repo_url}:${release_version}
```

4. Return to the `infra` directory and re-apply the `ecs` terraform project passing in the newly created image version to the  release_version variable.

```bash
cd ../infra; terraform apply -var="release_version=${release_version}"
```

## TO-DO
---
Add VPC Module With Private Subnet