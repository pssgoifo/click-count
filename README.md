# Click Count application

[![Build Status](https://travis-ci.org/xebia-france/click-count.svg)](https://travis-ci.org/xebia-france/click-count)

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Requirements](#requirements)
- [Setup](#setup)
  - [Create a service account user](#create-a-service-account-user)
  - [Deploy the infra](#deploy-the-infra)
  - [Setup your AWS console user to work with EKS (optional)](#setup-your-aws-console-user-to-work-with-eks-optional)
- [CI/CD](#cicd)

<!-- /code_chunk_output -->


This java application is a revolutionary Click Counter brought to you by Click Paradise&trade;.

## Requirements

* terraform 0.12.13+ (or Docker)
* kubectl
* aws-cli
* GitHub CLI 1.4+

```bash
aws eks --region us-east-1 update-kubeconfig --name "terraform-eks-clickcount"
kubectl edit -n kube-system configmap/aws-auth
```

## Setup

Clone the repository.

```bash
git clone git@github.com:pssgoifo/click-count.git
cd click-count/
```

### Create a service account user

Using the AWS console or CLI, create a suitable service account user for terraform and safeguard the credentials.

### Deploy the infra

**First time only**, we create the terraform backend using a bootstrap module.

```bash
# Setup the AWS credentials
export AWS_ACCESS_KEY_ID=<access_key_id>
export AWS_SECRET_ACCESS_KEY=<access_key_secret>
export AWS_DEFAULT_REGION=<default_region>

# Deploy backend
cd infra/bootstrap/
terraform init
terraform plan
terraform apply
cd -
```

Deploy/update the infra

```bash
# Setup the AWS credentials
export AWS_ACCESS_KEY_ID=<access_key_id>
export AWS_SECRET_ACCESS_KEY=<access_key_secret>
export AWS_DEFAULT_REGION=<default_region>

# Deploy infra
cd infra/terraform/
terraform init
terraform plan
terraform apply
cd -

# @FIXME: deploy namespaces by hand until the token issue is fixed
aws eks --region us-east-1 update-kubeconfig --name "terraform-eks-clickcount"
kubectl apply -f manifests/namespace.yaml
```

### Setup your AWS console user to work with EKS (optional)

You don't need the AWS console in order to work with your brand new EKS cluster, you can use the `kubectl` CLI.

If you want to enable the EKS cluster in the AWS console, edit the configmap `aws-auth`.

```bash
# update your .kubeconfig using AWS cli
aws eks --region us-east-1 update-kubeconfig --name "terraform-eks-clickcount"
# open the configmap in your favorite editor
kubectl edit -n kube-system configmap/aws-auth
```

Insert/update the `mapUsers` map and save:

```yaml
mapUsers: |
  - userarn: arn:aws:iam::<aws_project_id>:user/<aws_username>
    username: <aws_username>
    groups:
      - system:masters
```

## CI/CD

Clickcount utilizes GitHub Actions (<https://docs.github.com/en/actions>) and gitflow (<https://danielkummer.github.io/git-flow-cheatsheet/>) to build and deploy itself.

```plantuml
@startuml
title CI/CD workflow
box codebase
participant develop
collections "feature/newfeature" as feature
collections "release/vX.X.X" as release
participant master
end box
box CI/CD
participant "github \n actions" as ci
participant "run-tests" as unit
participant "build-and-release" as build
participant "deploy-to-staging" as deploystaging
participant "deploy-to-prod" as deployprod
end box
box kubernetes
participant staging
participant prod
end box
database dockerhub

group feature branches
|||
create feature
develop -> feature : branch
activate feature
feature -> feature : awesome \n changes
return pull request
deactivate feature
destroy feature
== build ==
develop --> ci : triggers event
create unit
ci -> unit : triggers job
activate unit
create build
unit -> build : tests ok
destroy unit
activate build
build -> build : build and tag docker image
build -> dockerhub : push image to registry
build -> ci : end of worklow
destroy build
end

group release branches
|||
create release
develop -> release : branch

activate release
release -> master : pull request
release -> develop : pull request
deactivate release
destroy release
== build and deploy to staging ==
develop --> ci : triggers event
create unit
ci -> unit : triggers job
activate unit
create build
unit -> build : tests ok
destroy unit
activate build
build -> build : build and tag docker image
build -> dockerhub : push image to registry
|||
create deploystaging
build -> deploystaging
destroy build
activate deploystaging
deploystaging -> staging : deploy to namespace "staging"
staging -> dockerhub : pull docker image
dockerhub -> staging : <image>:sha-${GITHUB_SHA::7}
staging -> deploystaging : deploy ok
deploystaging -> ci : end of workflow
destroy deploystaging
== build and deploy to prod ==
master --> ci : triggers event
create unit
ci -> unit : triggers job
activate unit
create build
unit -> build : tests ok
destroy unit
activate build
build -> build : build and tag docker image
build -> dockerhub : push image to registry
|||
create deployprod
build -> deployprod
destroy build
activate deployprod
deployprod -> prod : deploy to namespace "staging"
prod -> dockerhub : pull docker image
dockerhub -> prod : <image>:sha-${GITHUB_SHA::7}
prod -> deployprod : deploy ok
deployprod -> ci : end of workflow
destroy deployprod
end

@enduml
```

![CI/CD Workflow](http://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/pssgoifo/click-count/develop/workflow.puml)