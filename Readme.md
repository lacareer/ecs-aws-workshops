The VPC used for all the labs must be deployed or exist before deploying any template

<!-- Prerequsisites -->
- Deploy the VPC infrastructure 01-ecs-express-mode/cloudformation/pre-req/one-vpc.yaml. 

- Wait for it to comlete  successfully

- Then import the public subnet for the ECS Express Mode infra, AWS::ECS::ExpressGatewayService, in express-mode.yaml

- Deploy express-mode.yaml. Waitfor it to comlete  successfully