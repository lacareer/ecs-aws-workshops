<!-- ECR Images -->
These lab uses images already pushed to aws Public ECR repo

<!-- Images -->
# Please read the README.md file (using Github bcs the m file is well formatted and links shows as link and not so VS Code) in 'retail-store-sample-app' folder to get info about the app and links to various images including the UI image I used in this workshop for demonstration purposes

<!-- Push image to ecr -->

1. Create an ECR image using the AWS console named: retail-store-sample-ui

2. I pull down the UI image from AWS and pushed it to an ECR repo in my account I created  using the following commands using the ca-central-region:

    -$ docker pull public.ecr.aws/aws-containers/retail-store-sample-ui:1.0.0

    -$ aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin 066638479762.dkr.ecr.ca-central-1.amazonaws.com/retail-store-sample-ui

    -$ docker tag public.ecr.aws/aws-containers/retail-store-sample-ui:1.0.0  066638479762.dkr.ecr.ca-central-1.amazonaws.com/retail-store-sample-ui:latest

    -$ docker push 066638479762.dkr.ecr.ca-central-1.amazonaws.com/retail-store-sample-ui:latest

3.     