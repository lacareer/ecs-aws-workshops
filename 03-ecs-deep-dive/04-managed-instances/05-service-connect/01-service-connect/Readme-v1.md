<!-- ECS Managed Instance -->
To see ECS instance to indicate that the task is on a managed instance do the below because the page ui has change since the lab was recorded and the screenshot differs

- Go to ECS
- Click on the Cluster
- Click on the service and click the specific service
- Click on the task under the chosen service
- Click on a task tab
- Click on the task
- Make sure the configuration tab is selected
- Under configuration section, click on the highlighted link immediately under "Container instance ID"
- In the general configuration section you will find the 'Instance ID' with value i-xxxxx.. underneath it
- Click on the instance ID under Instance ID
- This opens a summary page of the  instance where the task is placed and it indicated amongst other that it is 'Managed'

<!-- Verify the deployment -->
Wait for the service to reach a steady state:

    $ aws ecs wait services-stable --cluster $ECS_CLUSTER --services catalog --region $AWS_REGION

Then confirm the catalog tasks are running:

    $ aws ecs describe-services \
        --cluster $ECS_CLUSTER \
        --services catalog \
        --region $AWS_REGION \
        --query 'services[0].{status:status, running:runningCount, desired:desiredCount, serviceConnect:serviceConnectConfiguration.enabled}' \
        --output table

Confirm the UI tasks now have the Service Connect proxy:

    $ export UI_TASK_ARN=$(aws ecs list-tasks --cluster $ECS_CLUSTER --service-name $SERVICE_NAME --region $AWS_REGION --query 'taskArns[0]' --output text)

    $ aws ecs describe-tasks \
        --cluster $ECS_CLUSTER \
        --tasks $UI_TASK_ARN \
        --region $AWS_REGION \
        --query 'tasks[0].containers[*].name' --output json        

<!-- Test end-to-end connectivity -->
Wait for the new tasks with ECS Exec enabled to start:

    $ aws ecs wait services-stable --cluster $ECS_CLUSTER --services $SERVICE_NAME --region $AWS_REGION

Get a running task ARN and verify that Service Connect resolves the catalog name from inside the UI task by listing products:

    $ export UI_TASK_ARN=$(aws ecs list-tasks --cluster $ECS_CLUSTER --service-name $SERVICE_NAME --region $AWS_REGION --query 'taskArns[0]' --output text)

    $ aws ecs execute-command \
        --cluster $ECS_CLUSTER \
        --task $UI_TASK_ARN \
        --container application \
        --interactive \
        --command "curl -s http://catalog:8080/catalog/products" \
        --region $AWS_REGION

You should see a healthy response from the Catalog service. This confirms that the Service Connect proxy inside the UI task resolves catalog and routes the request to a healthy Catalog task.

You can also open the retail store in your browser to see the catalog page:

    $ echo "http://${ALB_URL}/catalog"   

<!-- Generate traffic -->
Use the hey load testing tool (pre-installed in the IDE) to send requests to the UI service through the ALB. The UI calls the Catalog on each request, so this generates traffic across both services:

    $ hey -n 200 -c 10 http://${ALB_URL}/catalog

This sends 200 requests with 10 concurrent connections. Wait for it to complete before checking metrics.

View Service Connect metrics
Service Connect publishes metrics under the Amazon/ECS namespace in CloudWatch. Each metric includes dimensions for the discovery name (the service being called) and the target discovery name (the service handling the request).

List the available Service Connect metrics:

    $ aws cloudwatch list-metrics \
        --namespace "AWS/ECS" \
        --dimensions Name=ServiceName,Value=catalog \
        --region $AWS_REGION \
        --query 'Metrics[*].MetricName' --output json   

Query specific metrics
Check the request count for the Catalog service over the last 10 minutes:

    $ aws cloudwatch get-metric-statistics \
        --namespace "AWS/ECS" \
        --metric-name RequestCount \
        --dimensions Name=ServiceName,Value=catalog Name=ClusterName,Value=${ECS_CLUSTER} Name=DiscoveryName,Value=catalog-port \
        --start-time $(date -u -v-10M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
        --period 60 \
        --statistics Sum \
        --region $AWS_REGION

Check the average response time for calls from the UI to the Catalog:

    $ aws cloudwatch get-metric-statistics \
        --namespace "AWS/ECS" \
        --metric-name TargetResponseTime \
        --dimensions Name=ServiceName,Value=ui Name=ClusterName,Value=${ECS_CLUSTER} Name=TargetDiscoveryName,Value=catalog-port \
        --start-time $(date -u -v-10M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
        --period 60 \
        --statistics Average \
        --region $AWS_REGION     

<!-- Best Practices -->
Now that you have Service Connect running between the UI and Catalog services, this section covers recommendations from AWS documentation for production deployments.

# Namespace design
Organize namespaces by environment or application boundary:

One namespace per environment: production, staging, development
Services that need to communicate belong in the same namespace
# Network isolation with security groups
Each task in awsvpc network mode has its own unique IP address and security group. Configure the security group to allow incoming connections only from the specific upstream services that need to talk to that service. Reference security groups by ID (not CIDR) since task IPs are dynamic.

For example, the Catalog security group should allow inbound traffic on port 8080 only from the UI security group.

# Proxy resource allocation
The Service Connect proxy container consumes CPU and memory from your task's resource allocation. AWS recommends adding additional resources to your task definition to account for the proxy:

At minimum, add 256 CPU units and 64 MiB of memory
For high-throughput services (500+ requests per second), allocate more CPU
For large namespaces (100+ services or 2000+ tasks), allocate more memory
For current sizing guidance, see Service Connect proxy resources .

# Outlier detection and retries
Service Connect configures the proxy with built-in resilience:

Outlier detection: the proxy monitors connection failures to each target and temporarily removes unhealthy targets from the load balancing pool.
Retries: failed connections are automatically retried, with each retry avoiding the host from the previous attempt.
Timeout: the proxy enforces a maximum wait time for upstream responses. You can adjust this with the perRequestTimeout and idleTimeout parameters.
For current default values, see Service Connect proxy configuration .

# TLS encryption
Service Connect supports mutual TLS for encrypted service-to-service traffic using AWS Private CA. Service Connect handles certificate issuance, rotation, and termination automatically. TLS requires awsvpc networking mode and does not support bridge mode.

For configuration details, see TLS configuration for Service Connect .                 