<!-- Scheduled Scaling -->

# Important
You must have completed the following chapters as pre-requisites for this lab:Target Tracking Scaling

In this section, we'll configure ECS Service Auto Scaling using Scheduled Scaling. This includes setting up time-based scaling rules for services that have predictable load patterns. We'll create a scheduled scaling action for the UI service using a cron expression to test its scale-out and scale-in by adjusting the minimum value.

# The following example is intended for testing purpose and will execute 2 minutes after the command is run. In a production environment, you need to establish schedules for consistent, predictable patterns.

Since we've already covered registering the UI service as a scalable target with Application Auto Scaling in the Target Tracking section, we'll skip this part. Let's run the following command to increase the minimum capacity from 2 to 5 in 2 minutes from the current time:

-$ aws application-autoscaling put-scheduled-action \
 --service-namespace ecs \
 --scalable-dimension ecs:service:DesiredCount \
 --resource-id service/retail-store-ecs-cluster/ui \
 --scheduled-action-name "test-scale-up" \
 --schedule "at($(date -u -d "+2 minutes" "+%Y-%m-%dT%H:%M:%S"))" \
 --scalable-target-action MinCapacity=5,MaxCapacity=10

To verify the scheduled action, we'll set up a 150 second countdown timer and run the command to check the scheduled action. Use the following command to start the countdown timer:

-$ echo "Starting timer for 2 plus minutes..." && sleep 150 && echo "Time's up! and you can run the next command"

We will wait for 150 seconds for the scheduled action to trigger and deploy instances. After the timer completes, execute the following command to observe the scheduled action. You can observe list of 5 ECS tasks.

-$ aws ecs describe-tasks \
 --cluster retail-store-ecs-cluster \
 --tasks $(aws ecs list-tasks --cluster retail-store-ecs-cluster --service-name ui --query 'taskArns[]' --output text) \
 --query "tasks[*].[group, launchType, lastStatus, healthStatus, taskArn]" --output table

Let's run the following command to scale back in 2 minutes from current time. This command will set the minimum capacity from 5 to 2, which is the original capacity:

-$ aws application-autoscaling put-scheduled-action \
 --service-namespace ecs \
 --scalable-dimension ecs:service:DesiredCount \
 --resource-id service/retail-store-ecs-cluster/ui \
 --scheduled-action-name "test-scale-in" \
 --schedule "at($(date -u -d "+2 minutes" "+%Y-%m-%dT%H:%M:%S"))" \
 --scalable-target-action MinCapacity=2,MaxCapacity=10


<!-- Implementing Real-World Scheduled Scaling -->
As implemented above, the commands can be adjusted to schedule scaling during the necessary time windows based on your application's requirements. For example, scheduled scaling can be set to trigger at 9 AM UTC and 6 PM UTC each day, which may align with peak usage times for a global application. Here’s how you can configure these daily scheduled scaling actions.

The following example can be applied in real life, but there is a high probability that it will not execute during the workshop due to time zone differences.

The following command initiates the scale-out activity, raising the number of tasks to 5 every day at 9:00 AM UTC to accommodate anticipated increased traffic during the day:

-$ aws application-autoscaling put-scheduled-action \
    --service-namespace ecs \
    --scalable-dimension ecs:service:DesiredCount \
    --resource-id service/retail-store-ecs-cluster/ui \
    --scheduled-action-name "week-day-scale-out" \
    --schedule "cron(0 9 ? * MON-FRI *)" \
    --scalable-target-action MinCapacity=5,MaxCapacity=10

The following command initiates the scale-in activity, reducing the number of tasks during off-peak hours. For instance, we will scale down our UI service at 6 PM each day.

-$ aws application-autoscaling put-scheduled-action \
    --service-namespace ecs \
    --scalable-dimension ecs:service:DesiredCount \
    --resource-id service/retail-store-ecs-cluster/ui \
    --scheduled-action-name "week-day-scale-in" \
    --schedule "cron(0 18 ? * MON-FRI *)" \
    --scalable-target-action MinCapacity=2,MaxCapacity=10