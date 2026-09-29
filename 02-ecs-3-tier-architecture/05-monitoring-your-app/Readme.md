<!-- Deployment -->
Deploy the resource in this order:

1. Deploy the VPC in pre-req/one-vpc.yaml

2. Wait for item 1 deploment to complete successfully

3. Deploy 02-ecs-3-tier-architecture/01-frontend/frontend.yaml

4. Wait for the deploment to complete successfully

5. Once completed, got to the AWS Console and copy the ALB url

6. Prefix it with http://<ALB_URL>, paste in a browser and hit enter. You should see the running UI App
