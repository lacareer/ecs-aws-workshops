THIS IS A CONTINUATION OF THE PREVIOUS MODULE


<!-- Deployment -->
Deploy the resource in this order:

1. Deploy the VPC in pre-req/one-vpc.yaml

2. Wait for item 1 deploment to complete successfully

3. Deploy 01-ecs-express-mode/cloudformation/02-frontend-backend/express-mode.yaml

4. Wait for item 3 deploment to complete successfully

*** commands ***


Run if you want to check if all services are stable and ready:

$ echo_y "Waiting for all backend services to stabilize..."

$ aws ecs wait services-stable --cluster default --services catalog-express cart-express orders-express checkout-express

$ echo_c "All backend services are stable!"

% Services and endpoints

UI_URL=<ENTER_UI_APPLICATION_URL>

echo_c "UI url: https://${UI_URL}"
echo_c "UI Topology page: https://${UI_URL}/topology"

CATALOG_URL=<ENTER_CATALOG_APPLICATION_URL>

echo_c "Catalog URL: https://${CATALOG_URL}"

CART_URL=<ENTER_CART_APPLICATION_URL>

echo_c "cart URL: https://${CART_URL}"

ORDERS_URL=<ENTER_ORDER_APPLICATION_URL>

echo_c "Orders URL: https://${ORDERS_URL}"

CHECKOUT_URL=<ENTER_CHECKOUT_APPLICATION_URL>

echo_c "Checkout URL: https://${CHECKOUT_URL}"



<!-- Create a VPC Cloudshell instance for initial -->
We need to create a VPC Cloudshell instance because the aside from the UI service, all others use internal ALB and can't be accessed outside the VPC. 

# catalog service
Select your custom vpc with a private subnets in it and the CatalogSecurityGroupIngress resource with name retail-store-ecs-catalog-task and click create

Once done run the below to return just 2 products catalog items or remove the pipe (| jq '.[0:2]') to get all catalog products:

~ $  curl --silent -H "Accept: application/json" https://ca-5e134ff50f30455da1c08c08c3013b70.ecs.us-east-1.on.aws/catalog/products | jq '.[0:2]'

    [
        {
            "id": "a1258cd2-176c-4507-ade6-746dab5ad625",
            "name": "Aqua Ace GT",
            "description": "Transform your luxury sports car into a high-speed submarine with the push of a button. Features hydro-jet propulsion, underwater navigation, and oxygen recycling system for up to 8 hours. Includes coral-proof paint coating.",
            "price": 10000,
            "tags": [
            {
                "name": "vehicles",
                "displayName": "Vehicles"
            }
            ]
        },
        {
            "id": "d4edfedb-dbe9-4dd9-aae8-009489394955",
            "name": "Audio-Illusion Spinner",
            "description": "Professional-grade sonic illusion generator disguised as a simple yo-yo. Creates realistic sound effects from footsteps to full orchestras. Includes comprehensive training manual and anti-tangle technology.",
            "price": 190,
            "tags": [
            {
                "name": "accessories",
                "displayName": "Accessories"
            }
            ]
        }
    ]

# order service
~ $ curl --silent -H "Accept: application/json"   https://or-280eb57a8dab4095a21463d8a545226d.ecs.us-east-1.on.aws/orders | jq '.[0:2]'

    []


<!-- Connect UI to BackEnd Services -->
Once all the backend services have been deployed and stable.
Run the below to reduce the canary baked time during UI service deployment or skip if you dont mind waiting 3mins:

    $ aws ecs update-service \
        --cluster default \
        --service ui-express \
        --deployment-configuration '{
            "canaryConfiguration": {
            "canaryPercent": 5,
            "canaryBakeTimeInMinutes": 0
            }
        }'

We reduce the canary bake time to zero only for this workshop to save time. In production, keep it at 3 minutes or higher. The canary bake time is the window during which only a small percentage of traffic (5%) reaches the new version. If you have CloudWatch Alarms configured (on 5xx rate, latency, etc.), this window gives the alarms time to detect problems that health checks miss (e.g., a bug that returns wrong data but still responds 200 OK). Without canary bake time, traffic shifts to 100% immediately after health checks pass, and all users are impacted if there's an application-level issue.


<!-- Autoscale the UI Service --> 
# Default scaling configuration
When you create an Express Mode service without specifying --scaling-target, these defaults are applied:

Parameter	                Default value
Minimum tasks	            1
Maximum tasks	            20
Scaling metric	            AVERAGE_CPU
Target value	            60%

# Available scaling metrics
Express Mode supports three scaling metrics:

Metric	                    Best for
AVERAGE_CPU	                CPU-bound workloads (data processing, computation)
AVERAGE_MEMORY	            Memory-intensive workloads (caching, in-memory data)
REQUEST_COUNT_PER_TARGET	Web applications where traffic volume drives scaling

# Update the scaling configuration
Express Mode created the service with AVERAGE_CPU as the default scaling metric. 
For a web application like ours, scaling based on traffic volume is more responsive. 
Let's switch to REQUEST_COUNT_PER_TARGET with a target of 50 requests per task, and set a minimum of 2 tasks for high availability:


Auto-scaling the UI service can be done using the CLI or CloudFormation as shown below:

# CLI


$ aws ecs update-express-gateway-service \
  --service-arn arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:service/<ECS_CLUSTER_NAME>/ui-express \
  --scaling-target '{
    "minTaskCount": 2,
    "maxTaskCount": 10,
    "autoScalingMetric": "REQUEST_COUNT_PER_TARGET",
    "autoScalingTargetValue": 50
  }'

# CloudFormation addition to Existing UI Service

  UiExpressService:
    Type: AWS::ECS::ExpressGatewayService
    Properties:
      ServiceName: !Ref UiServiceName
      Cpu: !Ref Cpu
      Memory: !Ref Mem
      Cluster: !Ref EcsCluster
      ExecutionRoleArn: !GetAtt RetailStoreEcsTaskExecutionRole.Arn
      InfrastructureRoleArn: !GetAtt EcsExpressInfrastructureRole.Arn
      TaskRoleArn: !GetAtt EcsExpressTaskRole.Arn
      HealthCheckPath: !Ref UiHealthCheckPath
      PrimaryContainer:
      ....
      ....
      ....
      ScalingTarget:
        AutoScalingMetric: "REQUEST_COUNT_PER_TARGET"
        AutoScalingTargetValue: 50 #50 requests per task as target. Above this there is a scale-out. Default is 60
        MaxTaskCount: 10 #Total number of task when it scales-out
        MinTaskCount: 2 #Total number of task when it scales-in

<!-- command -->

    echo_y "Waiting for ui-express service to stabilize with the new task definition..."
    aws ecs wait services-stable --cluster default --services ui-express
    echo_c "ui-express service is stable!"

<!-- Generate load -->
Use the hey [https://github.com/rakyll/hey] load testing tool (pre-installed in your IDE) to send sustained traffic to the UI service. 
The & at the end runs it in the background so you can continue using the terminal:

    UI_URL=$(get_express_endpoint default ui-express)

    hey -n 1000000 -c 2 -q 5 https://${UI_URL}/home &

<!-- Monitor while waiting for the alarm to trigger -->
The High alarm triggers when the metric exceeds 50 for 3 consecutive 1-minute periods (~3-5 min).

You can monitor the alarm state with a loop that prints every second:

    $ echo "State    Threshold"

    $ for i in $(seq 1 300); do
        aws cloudwatch describe-alarms \
            --alarm-name-prefix "TargetTracking-service/default/ui-express-AlarmHigh" \
            --query 'MetricAlarms[0].{State:StateValue,Threshold:Threshold}' \
            --output text
        sleep 1
        done

heck the running tasks. You should see the task count increasing beyond 2:

    $ aws ecs describe-services --cluster default --services ui-express \
        --query 'services[0].{desiredCount:desiredCount,runningCount:runningCount}' \
        --output table

<!-- Stop the load test -->

    $ pkill -9 hey        

After several minutes without load, the service will automatically scale back down to the minimum of 2 tasks (the Low alarm needs 15 consecutive minutes below threshold before triggering scale-in). If you don't want to wait for the automatic scale-in, you can force the service back to 2 tasks:

    $ aws ecs update-service --cluster default --service ui-express --desired-count 2

    $aws ecs describe-services --cluster default --services ui-express \
        --query 'services[0].{desiredCount:desiredCount,runningCount:runningCount}' \
        --output table

<!-- Trigger a Rollback -->
It's Friday afternoon. A colleague pushes an update with the wrong container image. "Oops, I deployed the NGINX base image instead of our app!" Let's see if Express Mode's safety net catches this before customers notice.

Every update in Express Mode goes through a canary deployment  phase. If health checks fail during the canary, Express Mode automatically rolls back. Your users are never impacted. This is the ECS deployment circuit breaker  in action.

# Deploy a broken image
Let's update the UI service with an image that will fail health checks (wrong health check path for the container):   

    $ aws ecs update-express-gateway-service \
        --service-arn arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:service/default/ui-express \
        --primary-container '{
            "image": "public.ecr.aws/nginx/nginx:latest",
            "containerPort": 80
        }' \
        --monitor-resources

Press q to close the monitoring view. The deployment will continue in the background.        

    $ q

<!-- Observe the canary phase -->
Open the ECS console to watch the deployment:

Open ECS Service Deployments and you will see:
- The new revision launches tasks and the ALB starts health check probes.
- The health checks fail (404). The tasks are marked unhealthy and replaced.
- After 3 consecutive failures, the circuit breaker triggers and Express Mode automatically rolls back to the previous revision.

<!-- Observe the rollback -->
Watch the deployment lifecycle in the console. It progresses through three states: 
    - IN PROGRESS (canary tasks launching), 
    - ROLLBACK IN PROGRESS (circuit breaker triggered, reverting to previous revision), 
    - ROLLBACK SUCCESSFUL (cleanup complete, service restored):

You may also notice some 5XX errors in the ALB metrics during the canary phase. These are not errors seen by your users. 
They come from the ALB health check probes hitting the broken NGINX container (which doesn't have the /actuator/health endpoint). 
Since the canary only receives a small percentage of traffic and the health checks fail quickly, Express Mode rolls back before real user traffic is affected.

<!-- Verify the application is still healthy -->
    $ UI_URL=$(get_express_endpoint default ui-express)

    $ echo_c "Application: https://${UI_URL}"

Open the URL. You should see the Retail Store application still running with the previous good configuration. The bad deployment was rolled back automatically.

<!-- Key takeaway -->
You don't need to configure rollback rules, CloudWatch alarms for deployment health, or circuit breakers. 
Express Mode handles all of this automatically. 
Deploy with confidence: if something goes wrong, your users stay on the working version.