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

<!-- Verify -->

Alternatively, you can wait for the service to stabilize using the AWS CLI (~ 2 min):

    $ aws ecs wait services-stable --cluster retail-store-ecs-cluster --services ui

Once stable, view the running tasks using the CLI:

    $ aws ecs describe-tasks \
        --cluster retail-store-ecs-cluster \
        --tasks $(aws ecs list-tasks --cluster retail-store-ecs-cluster --query 'taskArns[]' --output text) \
        --query "tasks[*].[group, launchType, taskArn,containerInstanceArn]" --output table

To retrieve the load balancer URL, run:

    $ echo http://${ALB_URL} ; echo