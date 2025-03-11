<!-- ECR Images -->
These lab uses images already pushed to aws Public ECR repo

<!-- Images -->
# Please read the README.md file (using Github bcs the m file is well formatted and links shows as link and not so VS Code) in 'retail-store-sample-app' folder to get info about the app and links to various images including the UI image I used in this workshop for demonstration purposes

<!-- Push image to ecr -->
I pull down the UI image from AWS and pushed it to an ECR repo in my account I created  using the following commands:

$ docker pull public.ecr.aws/aws-containers/retail-store-sample-ui:1.0.0
ecs-aws-workshops