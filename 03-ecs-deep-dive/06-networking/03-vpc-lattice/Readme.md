<!-- NOTES -->

- vpc1-fe-be-sc.yaml contains both the frontend and backend services but the backend cart service deployed to one-vpc.yaml

- vpc2-fe-be-sc.yaml contains only the backend cart service deployed to lattice-vpc.yaml

<!-- Deployment -->
Deploy the templates in this other:

- Deploy the one-vpc.yaml and lattice-vpc.yaml in 01-ecs-express-mode/cloudformation/pre-req 

- vpc1-fe-be-sc.yaml 

- vpc2-fe-be-sc.yaml 

- Add the below to vpc1-fe-be-sc.yaml and redeploy to update it:

    # New parameter
    CartsServiceDnsName:
        Type: String
        Description: VPC Lattice carts-service DNS (from the VPC2 stack output), e.g. carts-service-xxxx.yyyy.vpc-lattice-svcs.<region>.on.aws

    # New UI task definition environment variable:
    - Name: RETAIL_UI_ENDPOINTS_CARTS            # <-- added: reach carts over VPC Lattice (HTTPS)
            Value: !Sub "https://${CartsServiceDnsName}" 

- Grab the  cart dns name from  vpc2-fe-be-sc.yaml  deployement

- Update vpc1-fe-be-sc.yaml using the console and by enter the value above. Every other thing should stay same


<!-- Test  -->

Follow lab doc to test interconnectivity using vpc lattice to see although the crt service is deployed in another vpc, the UI service connects to it and the checkout cart still works as shown by the recored in DDB