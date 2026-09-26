<!-- Prerequsisites -->
- Deploy the  VPC infrastructure, pre-req/one-vpc.yaml. Waitfor it to comlete  successfully

- Then import the public subnet for the ECS Express Mode infra, AWS::ECS::ExpressGatewayService, in express-mode.yaml

- Deploy express-mode.yaml. Waitfor it to comlete  successfully

<!-- View the app -->
-  Go to the ECS service, click on it to reveal all its details

- Copy and paste the Application URL under the service in the browser to view the application

<!-- Updating the app -->

- Update the environment variable for the primary container for the  ui-express (or whatever your service name is) service using CloudShell 

    <!-- cli command -->
    $ aws ecs update-express-gateway-service \
        --service-arn arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:service/default/ui-express \
        --primary-container '{
            "image": "public.ecr.aws/aws-containers/retail-store-sample-ui:1.5.0",
            "environment": [{
            "name": "RETAIL_UI_THEME",
            "value": "orange"
            }]
        }' \
        --monitor-resources

- OR update the environment variable for the primary container for the  ui-express (or whatever your service name is) service using CloudFormation 
  By commenting if not commented out [will now use the default Blue theme of the app] or uncommenting if commented [to use the orange theme] depending on what you started with, the cloudformation code below under the primary container

    <!-- cfn -->
        Environment:
            - Name: RETAIL_UI_THEME
                Value: !Ref UiTheme

- Go to the ECS service and under the Deployments tab to see the canary deployment

- Click on the ongoing deployment to see the  Green and Blue percentage of traffic respectively

- Refresh the browser several times to see the changed theme from Blue to Orange or Orange to Blue [the number of refresh will depend on the % of traffic being shifted to the green deployedment]