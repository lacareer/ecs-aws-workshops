
<!-- Service Auto Scaling -->
Since a single Fargate instance corresponds to a single ECS task, you need to specify task's CPU and memory during creating task definition. Therefore, it's crucial to right-size your Fargate tasks to ensure they can perform their duties with the desired performance level. If a task struggles due to insufficient CPU or memory for performing its functions, this indicates that the task is not correctly sized and might require additional resources. You can accurately assess the needs of your application by engaging in performance measurement, conducting comprehensive load testing, or closely observing key metrics.

Once you're confident that your tasks are appropriately sized, you can then scale horizontally by deploying additional tasks to handle more requests. Horizontal scaling is the preferred method for scaling cloud-native, containerized workloads.

Amazon ECS seamlessly integrates with Amazon CloudWatch to enable efficient scaling of ECS services based on real-time metrics. These metrics are transmitted from Amazon ECS to CloudWatch at one-minute intervals, allowing for precise monitoring and timely scaling decisions. When metrics exceed the thresholds defined in your scaling policy, CloudWatch triggers an alarm that adjusts the desired number of tasks within your service. This dynamic adjustment process increases the desired capacity during scale-out events and decreases it during scale-in events, ensuring optimal resource utilization.

Amazon ECS offers three sophisticated service scaling strategies:

1. Target Tracking Scaling: This method aims to maintain a specified scaling metric at a target value by automatically adjusting the number of tasks. Target tracking scaling is preferred for its simplicity and low maintenance requirements, making it an ideal choice for businesses seeking operational efficiency without constant manual intervention.

2. Step Scaling: This strategy provides greater control over scaling actions. Users can select metrics, set threshold values, and define step adjustments to specify the number of resources to add or remove. It also allows for customizable breach evaluation periods for metric alarms, offering a tailored approach to handling variable workloads effectively.

3. Scheduled Scaling: This method is best utilized when scaling actions can be anticipated based on known demand patterns. It's ideal for applications experiencing predictable traffic fluctuations, enabling proactive resource management to ensure service stability and performance during peak times.

These scaling methods empower organizations to harness the full potential of ECS, optimizing both cost and performance by aligning resource allocation with actual demand. By leveraging these strategies, businesses can ensure their applications remain responsive and efficient, regardless of fluctuations in workload or user demand.

<!-- Directory -->
On the command line, move into the lab directory; cd into 1-targetTracking-autoscaling

<!-- Target Tracking Scaling -->
In this section, we'll configure ECS Service Auto Scaling using Target Tracking Scaling. This includes determining which services to set up application autoscaling for and applying the appropriate scaling policies.

Let's register the UI service as a scalable target with Application Auto Scaling. The following command sets the scaling range for the UI Service from a minimum of 2 to a maximum of 10 tasks.

-$ aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --scalable-dimension ecs:service:DesiredCount \
    --resource-id service/retail-store-ecs-cluster/ui \
    --min-capacity 2 \
    --max-capacity 10

Next, we'll create a scaling policy for our scaling target.

First, create a JSON configuration file for the scaling policy. This configuration utilizes the predefined metric type of request count per target related to the Application Load Balancer that routes requests to the ECS service. In this case, we're aiming for 1,500 requests per ECS task (or target). Read https://docs.aws.amazon.com/autoscaling/ec2/userguide/examples-scaling-policies.html

# This scaling policy is only an example. You should understand the scaling profile of your particular workloads to determine the appropriate scaling metrics and thresholds before enabling autoscaling.  

cat << EOF > ui-scaling-policy.json
{
    "TargetValue": 1500,
    "PredefinedMetricSpecification": {
        "PredefinedMetricType": "ALBRequestCountPerTarget",
        "ResourceLabel": "app/ws-ecs-alb/ef429c628a78387e/targetgroup/ws-ecs-tg/5f4b052b224a702f
}
EOF

Note that the ResourceLabel above is formed as using: "app/my-alb/778d41231b141a0f/targetgroup/my-alb-target-group/943f017f100becff". Must  start with 'app'
- app/<load-balancer-name>/<load-balancer-id> is the final portion of the load balancer ARN
- targetgroup/<target-group-name>/<target-group-id> is the final portion of the target group ARN.

Now, apply the scaling policy with the following command:

-$ aws application-autoscaling put-scaling-policy \
    --service-namespace ecs \
    --scalable-dimension ecs:service:DesiredCount \
    --resource-id service/retail-store-ecs-cluster/ui \
    --policy-name ui-scaling-policy --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration file://ui-scaling-policy.json

<!-- Explore CloudWatch Alarm -->
When you navigate to the Alarms  tab in the CloudWatch service, you will see that the scaling policy has created 2 CloudWatch alarms.
The alarm status may vary depending on request numbers. For example, UI-AlarmLow triggers when requests fall below 1350 0r 90% of 1500 target.

<!-- Trigger Auto Scaling -->
In this section, we'll generate synthetic load for our UI service to observe its scaling behavior.

First, install the HTTP generator 'hey'. Download the installer at https://github.com/rakyll/hey?tab=readme-ov-file and install as below:

-$ sudo apt update


-$ sudo apt install hey

Secondly, verify the DNS name for the load balancer associated with our UI service. This environment variable should have been exported as part of the fundamental chapter.

-$ export RETAIL_ALB=$(aws elbv2 describe-load-balancers --name ws-ecs-alb --query 'LoadBalancers[0].DNSName' --output text)

-$ echo ${RETAIL_ALB}

Send  traffic to your ALB and  check your  alarms after 4mins:

-$ hey -n 1000000 -c 5 -q 40 http://$RETAIL_ALB/home &

Scaling activity will be triggered when the high alarm for the scaling metric breaches for 3 consecutive 1-minute periods. If you want to automatically wait until the alarm triggers, you can run this command (~ 4 min):

-$ sleep 90 && aws cloudwatch wait alarm-exists --alarm-name-prefix TargetTracking-service/retail-store-ecs-cluster/ui-AlarmHigh --state-value ALARM

When the alarm fires, you'll notice the service's task count scaling out from 2 to a higher number:

-$ aws ecs describe-tasks \
    --cluster retail-store-ecs-cluster \
    --tasks $(aws ecs list-tasks --cluster retail-store-ecs-cluster --query 'taskArns[]' --output text) \
    --query "tasks[*].[group, launchType, lastStatus, healthStatus, taskArn]" --output table

You can observe the associated high alarm with the scaling policy transitioning to the ALARM state in the CloudWatch console, as shown below.  
You can also check the Events tab  in the UI Service page to see the scaling activity, where the desired count increases beyond the initial task count.  

To stop the hey process, run the following command:

-$ pkill -9 hey

Normally, after several minutes, the number of tasks should scale back to the minimum of 2. However, for the sake of time, we can force the service to scale down by running the following commands:

-$ aws ecs wait services-stable --cluster retail-store-ecs-cluster --services ui

-$ aws ecs update-service \
    --cluster retail-store-ecs-cluster \
    --service ui \
    --task-definition retail-store-ecs-ui \
    --desired-count 2