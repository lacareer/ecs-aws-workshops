<!-- NOTES -->

- vpc1-fe-be-sc.yaml contains both the frontend and backend services but the backend cart service deployed to one-vpc.yaml

- vpc2-fe-be-sc.yaml contains only the backend cart service deployed to lattice-vpc.yaml

<!-- Deployment -->

Deploy the templates in this other:

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