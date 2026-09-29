NOTE THAT I ONLY USED THE UI SERVICE TO DEMO ECS BLUE/GREEN Deployment
YOU CAN DO SIMILAR FOR ALL THE OTHER SERVICES
THIS BECAUSE PLURALSIGHT LIMITS THE NUMBER OF CONTAINERS/TASK I CAN RUN AND MY ENVIRONMENT WAS ALWAY BEING TERMINATED

<!-- Deployment -->
Deploy the resource in this order:

1. Deploy the VPC in pre-req/one-vpc.yaml

2. Wait for item 1 deploment to complete successfully

3. Deploy either of: 

    -   02-ecs-3-tier-architecture/04-blue-green/frontend.yaml

    -   02-ecs-3-tier-architecture/04-blue-green/frontend-with-ecs-lifcycle-hook.yaml

4. Wait for the deploment to complete successfully

5. Once completed, got to the AWS Console and copy the ALB url

6. Prefix it with http://<ALB_URL>, paste in a browser and hit enter. You should see the running UI App


Read the notes below and then go to the testing section depending on which file was deployed

<!-- Notes and things to note about this setup -->
Lifecycle hook is optional. The workshop adds a POST_TEST_TRAFFIC_SHIFT manual-approval Lambda, but blue/green works without it. 

If you want it, you'd add an AWS::Lambda::Function (returning IN_PROGRESS/SUCCEEDED/FAILED) plus an ECSLifecycleHookRole (trust ecs.amazonaws.com, permission lambda:InvokeFunction on that function), then uncomment the LifecycleHooks block.

Test listener exposure. Port 8080 open to 0.0.0.0/0 mirrors the workshop but means your green environment is publicly reachable during validation. For anything beyond a workshop, restrict that ingress to a known CIDR or your own IP.

Rule priority collision. Both rules use Priority: 1 on different listeners, which is fine (priority is per-listener). Don't reuse priority 1 within the same listener if you add more rules.

Provider support. Native ECS blue/green in CloudFormation (the AdvancedConfiguration / DeploymentConfiguration.Strategy: BLUE_GREEN properties) is recent — make sure you're deploying in a region where it's available, otherwise CloudFormation will reject those properties.

Task definition port. Your UiTaskDefinition already maps container port 8080 and names the container application, which matches ContainerName above — no change needed there.

<!-- TEST BLUE/GREEN DEPLOYMENT WITHOUT ECS LIFECYCLE HOOKS frontend.yaml -->

To test blue/green deployment and the traffic shifting, change the value of the paramter below to one of [blue, green, orange] that is not currently its value

  UiTheme:
    Type: String

Once deployment is ongoing (you can see in the ecs console under deployments) and before it is complete open two browser tabs

- http://retail-store-alb-1546429840.us-east-1.elb.amazonaws.com    [has your blue/current production traffic]

- http://retail-store-alb-1546429840.us-east-1.elb.amazonaws.com:8080/     [has your green/soon-to-be production traffic]

During traffic shift to production, you will notice the green endpoint updates first while the blue is still same

Soon after the green update becomes the main endpoint receiving sent to the previous/main url: http://retail-store-alb-1546429840.us-east-1.elb.amazonaws.com

All the blue containers/task at this point blue tragets no longer receive traffic and are being shutdown

<!-- TEST BLUE/GREEN DEPLOYMENT WITH ECS LIFECYCLE HOOKS frontend-with-ecs-lifcycle-hook.yaml -->

To test blue/green deployment with ecs lifecycle hooks, do the following:

    - Pre-create an s3 bucket with name 'my-ecs-approval-bucket'  [this exact name because that is what the parameter is set in the deployed template]

    - create an 'approvals' folder in the bucket [this exact name because that is what the parameter is set in the deployed template]

    - create and upload the file ui-blue-green.txt into the bucket in /approvals folder [should be in my-ecs-approval-bucket/approvals/ui-blue-green.txt]


Then simulate success, in-progress and failure by changing the file content using below table during each deploy when change the value of the parameter below to one of [blue, green, orange] that is not currently its value

  UiTheme:
    Type: String

Basically, make sure to upload same file with same name each time [preferable b4 each new deployment] even if it will overwrite the old one in the bucket should versioning not be enabled

Change the only content of the file on line 1 to be either of:

- 'approved' [simulates SUCCEEDED], 

- 'any other string but approved' [simulates FAILED]

- And then with file not in location [simulate IN_PROGRESS]

Behavior summary:

Object at approvals/<revision-id>.txt	        .strip() value	                Hook returns	        Result
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Present	                                        approved	                    SUCCEEDED	            Production traffic shifts to green
Present	                                        anything else	                FAILED	                Deployment rolls back
Absent	                                            —	                        IN_PROGRESS	            Polls again in 30s (waits for you to add file with requiredstring)


If the file contains a string other than 'approved' you will see the blue/green rollback in action

Below is a sample of the lambda logs for an approved deployment
    ...
    ...
    START RequestId: 6064e993-3182-482b-8acf-6e6765d9ee6e Version: $LATEST
    2026-09-28T17:55:19.533Z
    Manual approval event: {'executionDetails': {'testTrafficWeights': {}, 'productionTrafficWeights': {}, 'serviceArn': 'arn:aws:ecs:us-east-1:671280668880:service/retail-store-ecs-cluster/ui', 'targetServiceRevisionArn': 'arn:aws:ecs:us-east-1:671280668880:service-revision/retail-store-ecs-cluster/ui/7017808489111628141'}, 'executionId': 'f3758e27-ac30-46e7-8f83-89b0f0423fac', 'lifecycleStage': 'POST_TEST_TRAFFIC_SHIFT', 'resourceArn': 'arn:aws:ecs:us-east-1:671280668880:service-deployment/retail-store-ecs-cluster/ui/exDpBfIu2nWvYW8n1jw01'}
    2026-09-28T17:55:19.533Z
    approvals/ui-blue-green.txt - Checking for approval file: s3://my-ecs-approval-bucket/approvals/ui-blue-green.txt
    2026-09-28T17:55:22.024Z
    approvals/ui-blue-green.txt - Check failed!: approvals/ui-blue-green.txt
    2026-09-28T17:55:22.045Z
    approvals/ui-blue-green.txt - Approval file found: FAILED
    ...
    ...

