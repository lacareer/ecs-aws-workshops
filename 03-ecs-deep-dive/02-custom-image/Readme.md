This module is same as the previous just that you have to create ECR repo where the UI container image is stored

The AWS ARN of the ECR repo is now referenced in the task definition  with the image tag appended as below:

    <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/<ECR_REPO_NAME>:<IMAGE_TAG>

    <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/retail-store-ui-custom:v1.0

Below is a sample Dokcerfile for the UI service that can also be modified to pull the images of all other services and push to their respective ECR repos


<!-- Dockerfile -->

    # Use the retail store UI as the base image

    FROM public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.3

    # Bake the orange brand theme into the image

    ENV RETAIL_UI_THEME=orange

    # The base image already defines EXPOSE 8080 and ENTRYPOINT

    # We inherit those settings automatically

    EOF

You could also pull the image using the command line, tag it as needed, log into ECR, and push to it:

    $ aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<your-region>.amazonaws.com

    $ docker tag e9ae3c220b23 aws_account_id.dkr.ecr.region.amazonaws.com/my-repository:tag

    $ docker push aws_account_id.dkr.ecr.region.amazonaws.com/my-repository:tag

Note that you might need to pass a profile name, --profile <PROFILE_NAME>, if you have more than one profile configured

    $ aws ecr get-login-password --region <your-region> --profile <your-profile-name> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<your-region>.amazonaws.com

The rest of the lab is just same as  the previous module once your task definition references the images in your ECR repo