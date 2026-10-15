<!--    Managed Daemons -->

Deploy the template and following the lab doc to complete the exercises using the commands. Some of the command are shown in the sections.

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


<!-- *** Notes and commands *** -->

# Check daemon status
    $ aws ecs describe-daemon \
        --daemon-arn arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:daemon/${ECS_CLUSTER}/retail-store-cwagent \
        --region $AWS_REGION --no-cli-pager

Look for "status": "ACTIVE" and check the currentRevisions section — it shows how many instances are running the daemon (totalRunningCount).

# Monitor the deployment
Track the deployment progress:

    $ export DAEMON_ARN=arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:daemon/${ECS_CLUSTER}/retail-store-cwagent

    $ aws ecs list-daemon-deployments \
        --daemon-arn $DAEMON_ARN \
        --region $AWS_REGION --no-cli-pager

# Verify one daemon task per instance
Once the deployment reaches SUCCESSFUL, confirm that exactly one daemon task runs on each container instance:

    $ echo "=== Tasks per container instance ==="
    $ for CI in $(aws ecs list-container-instances --cluster $ECS_CLUSTER --region $AWS_REGION --query 'containerInstanceArns[]' --output text); do
        CI_ID=$(echo $CI | awk -F/ '{print $NF}')
        echo ""
        echo "Instance: $CI_ID"
        aws ecs list-tasks --cluster $ECS_CLUSTER --container-instance $CI_ID --region $AWS_REGION \
            --query 'taskArns[]' --output text | tr '\t' '\n' | while read TASK; do
            aws ecs describe-tasks --cluster $ECS_CLUSTER --tasks $TASK --region $AWS_REGION \
                --query 'tasks[0].[group, lastStatus, launchType]' --output text
        done
    done

You should see each instance running both a daemon:retail-store-cwagent task and a service:ui task. The daemon task uses MANAGED_INSTANCES as the launch type.

# Observe start-before-stop ordering
The daemon task always starts before application tasks on a newly provisioned instance. You can verify this by comparing the startedAt timestamps:

    $ aws ecs describe-tasks \
        --cluster $ECS_CLUSTER \
        --tasks $(aws ecs list-tasks --cluster $ECS_CLUSTER --region $AWS_REGION --query 'taskArns[]' --output text) \
        --region $AWS_REGION \
        --query 'tasks[*].[group, startedAt, lastStatus]' --output table    

# Verify host metrics in CloudWatch
The CloudWatch Agent daemon is now collecting host CPU and memory metrics. After approximately 2 minutes, check for metrics in the ECSManagedDaemonWorkshop namespace:

    $ aws cloudwatch list-metrics \
        --namespace ECSManagedDaemonWorkshop \
        --recently-active PT3H \
        --region $AWS_REGION \
        --query 'Metrics[].{name:MetricName,dims:Dimensions}' --output table

You should see metrics including cpu_usage_idle, cpu_usage_user, cpu_usage_system, mem_total, mem_available, and mem_used_percent.

To view actual values:

    $ aws cloudwatch get-metric-statistics \
        --namespace ECSManagedDaemonWorkshop \
        --metric-name mem_used_percent \
        --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-10M +%Y-%m-%dT%H:%M:%SZ) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
        --period 60 --statistics Average \
        --region $AWS_REGION    

# Push a custom StatsD metric from an application task
This is the key capability that managed daemons unlock: application tasks can push custom metrics to the daemon at the daemon bridge IP address 169.254.172.2:8125, without any changes to the application task definition.

First, enable ECS Exec on the UI service so we can run commands inside a running task.

    $ export UI_TASK_ARN=$(aws ecs list-tasks --cluster $ECS_CLUSTER --service-name $SERVICE_NAME \
        --region $AWS_REGION --query 'taskArns[0]' --output text)

    $ aws ecs execute-command \
        --cluster $ECS_CLUSTER \
        --task $UI_TASK_ARN \
        --container application \
        --interactive \
        --command "/bin/sh" \
        --region $AWS_REGION

From inside the container, send StatsD metrics to the daemon:

    # Send a counter metric
    $ echo "workshop.orders.count:1|c" > /dev/udp/169.254.172.2/8125

    # Send a gauge metric
    $ echo "workshop.cart.items:5|g" > /dev/udp/169.254.172.2/8125

    # Send multiple increments
    $ for i in $(seq 1 10); do
        echo "workshop.page.views:1|c" > /dev/udp/169.254.172.2/8125
    done

    $ echo "Metrics sent!"
    exit   

After approximately 1–2 minutes, verify the custom metrics appear in CloudWatch:

    $ aws cloudwatch list-metrics \
        --namespace ECSManagedDaemonWorkshop \
        --recently-active PT3H \
        --region $AWS_REGION \
        --query 'Metrics[?contains(MetricName, `workshop`)].MetricName' --output json

You should see workshop_orders_count, workshop_cart_items, and workshop_page_views — custom business metrics published through the daemon, with zero changes to the UI service's task definition.         