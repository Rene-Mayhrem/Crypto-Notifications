# NBA Game Notifications Alert System 

## Overview

This project is an NBA Game Notifications Alert System that fetches NBA game data and sends notifications via Amazon SNS. The notifications include game status, scores, and other relevant details.

## Steps to Set Up and Test

1. **Create Dockerfile and docker-compose.yml**: Create the `Dockerfile` and `docker-compose.yml` in your project directory.
2. **Build docker image**: Run `docker-compose.yml` to build the Docker image.
3. **Run terraform**: Run the `docker-compose up` to start the container and apply the Terraform configuration.

4. Create a new permission policy and add the following code
5. Create a new IAM role and assign the created policy
6. Create a SNS Topic
7. Add a subscriber to the SNS topic
8. Create a Lambda function
9. Create Environment variables 