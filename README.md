<!--
 Copyright 2022 Meta Mind AB
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
     http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
-->

# SME Public Profile Infrastructure
Parent infrastructure project for easy deployment of services related to public profiles

> 🚧 **Warning**
>
> It is currently not possible for developers not associated with Normative to
> start this project as it requires access to protected resources.

## TL;DR

For first time installation, run: `npm run submodule:checkout && npm run submodule:install`

To start developing locally, run: `npm start`

To verify local installation, browse to [http://localhost:3000/?id=1153&isic=2&region=Sweden](http://localhost:3000/?id=1153&isic=2&region=Sweden)
## First time setup

To check out all git submodules and install all dependencies, run:

```
npm run submodule:checkout
npm run submodule:install
```

## Switching branches

To check out the develop branch, run:

```
npm run checkout:develop
```

You can check out a branch with a given prefix (e.g. SMCH-xx) in all submodules by running:

```
./scripts/checkout SMCH-xx
```

## Running locally

To run services locally, do:

```
npm start
```

All services will run in docker containers with development environment set up.

Individual services can also be stopped an run locally (e.g. through VS Code), and they will still connect
to the proper services by copying `.env.local` into `.env` in their relevant submodule folders.

Once everything is running, you can access the client by browsing to: [http://localhost:3000/?id=1153&isic=2&region=Sweden](http://localhost:3000/?id=1153&isic=2&region=Sweden)

## Deployment (staging)

Prerequisites:

- Install docker, docker-cli, docker compose v2, AWS CLI.
- Set up your AWS CLI credentials.
- Set up an AWS CLI *profile* that is configured to use an IAM user (+ possible
  Role) with the permissions necessary to (a) push docker images to ECR, and (b)
  deploy to ECS.

  Option 1 (simple but scary):

  Set up an AWS profile configured for an IAM user that has direct
  administrative access (eg, an IAM user that is in the `ci` group).

  Option 2 (complicated but restricts access more):

  This is complicated... basically you need to set things up so that you have an
  AWS CLI profile that can have *temporary session credentials* associated with
  it, and to make it actually usable you need a helper script to manage those
  credentials. At the start of your session (eg, once per day) you run the
  helper to get session credentials that are *for your own IAM user*, but
  under role `SMEPublicProfile-ManualDeployStagingRole` so the permissions are
  the role permissions (restricted), not your general IAM user permissions.

  Then the docker context (see below) can be configured to use this AWS CLI
  profile, and it will have the necessary credentials to deploy.

- Create a docker ecs 'context' using `docker context create ecs normative`. The
  context should be configured to use the AWS CLI profile from the previous
  step.

Per-session setup:

- Since all AWS CLI access (including through docker compose) needs MFA, and MFA
  sessions have a time limit, you will need to get *session credentials* using
  your MFA token. (Unless you're using an IAM user that doesn't require MFA).
- To push docker images to AWS, docker CLI needs credentials. Get these by
  running:

  ```
  aws --profile ${AWS_PROFILE_WITH_CREDS:-default} ecr get-login-password | docker login --username AWS --password-stdin 'ACCOUNT-ID.dkr.ecr.eu-central-1.amazonaws.com'
  ```

To deploy:

- To push a locally built Docker image:
  https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html

- To update the service(s) running in staging:

  ```
  docker context use normative
  docker compose up -f docker-compose.deploy.yml
  ```

## Docker Compose, ECS, and Cloud Formation

Deployment on AWS is managed through docker compose (as described above).
This uses Docker ECS integration, which is documented here:
https://docs.docker.com/cloud/ecs-integration/

Docker ECS integration works by converting the docker-compose definition to
an AWS CloudFormation template. Because we need to adjust the configuration in
ways that docker-compose does not natively support, the compose file also
includes CloudFormation template 'overlays' which are applied on top of the
initial conversion output. You can get the combined/final CloudFormation
template by running `docker compose -f docker-compose.deploy.yml convert`.

The customization of the template does the following:

- Remove the docker-compose generated ELB Listeners, since we want to serve
  all the services through a *single* listener (ie, single public-facing port)
  and route to the services based on request path.

- Define the custom listener, and path routing rules for it.

- Adjust the resource dependencies accordingly.

- Adjust the LoadBalancer security groups to add it to the HTTP+HTTPS group
  (which already exists; that group is not being defined as part of the stack),
  so that the LoadBalancer can accept traffic from the public internet.

- Sets the VPC to use.

## Contributing

This project is maintained by Normative but currently not actively seeking external contributions. If you however are interested in contributing to the project please [sign up here](https://docs.google.com/forms/d/e/1FAIpQLSe80c9nrHlAq6w2vUbeFSPVGG7IPqorKMkizhHJ98viwnT-OA/viewform?usp=sf_link) or come [join us](https://normative.io/jobs/).

Thank you to all the people from Google.org who were critical in making this project a reality!
- John Bartholomew ([@johnbartholomew](https://github.com/johnbartholomew))

## License
Copyright (c) Meta Mind AB. All rights reserved.

Licensed under the [Apache-2.0 license](/LICENSE)
