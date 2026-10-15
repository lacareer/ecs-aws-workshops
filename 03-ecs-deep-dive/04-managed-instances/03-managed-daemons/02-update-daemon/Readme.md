<!--  Managed Daemons PID and IPC Namespace Sharing-->

The daemon task definition has been updated to increase its memory reservation and add a disk metric collector - as shown in daemon.yaml

- Deploy the update template(note that the previous lab deploy should still be running to see the rolling update in a action)

- Go to the lab doc and go to the "Observe the rolling deployment"


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

<!-- Update template -->
Updated cpu and mem properties for the task definition of the Daemon and redeploy
Watch the rolling deployment using the commands below:

# Trigger the rolling update (no need to run this cloudformation does this automatically)
Update the daemon to use the new revision:

aws ecs update-daemon \
    --daemon-arn arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:daemon/${ECS_CLUSTER}/retail-store-cwagent \
    --daemon-task-definition-arn $NEW_TASKDEF_ARN \
    --capacity-provider-arns arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:capacity-provider/${CP_ARN} \
    --deployment-configuration '{"drainPercent":25,"bakeTimeInMinutes":0}' \
    --region $AWS_REGION


# Observe the rolling deployment
Amazon ECS now performs a drain-provision-replace cycle:

- Drains a batch of instances (controlled by drainPercent)
- Provisions replacement instances with the updated daemon
- Starts the new daemon task first (start-before-stop)
- Migrates application tasks to the new instances
- Terminates the old instances

Monitor the deployment:
    <!-- note that you may have to run this command several times to to see the new cw-agent task got from IN_PROGRESS to SUCCESSFUL -->
    $ aws ecs list-daemon-deployments \
        --daemon-arn arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:daemon/${ECS_CLUSTER}/retail-store-cwagent \
        --region $AWS_REGION --no-cli-pager


For more detail on a specific deployment:

    export DEPLOYMENT_ARN=$(aws ecs list-daemon-deployments \
        --daemon-arn arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:daemon/${ECS_CLUSTER}/retail-store-cwagent \
        --region $AWS_REGION \
        --query 'daemonDeployments[0].daemonDeploymentArn' --output text)

    $ aws ecs describe-daemon-deployments \
        --daemon-deployment-arns $DEPLOYMENT_ARN \
        --region $AWS_REGION --no-cli-pager        

The response includes:

- targetDaemonRevision.totalRunningInstanceCount — how many instances run the new daemon
- circuitBreaker.status — MONITORING during rollout, MONITORING_COMPLETE when done
- circuitBreaker.failureCount — number of failures detected (triggers rollback at threshold 3)

The deployment output tells you exactly where the rollout stands:

- sourceDaemonRevisions shows instances still running the old daemon revision. Watch totalRunningInstanceCount decrease and totalDrainingInstanceCount increase as ECS drains old instances.
- targetDaemonRevision shows instances running the new daemon revision. Watch totalRunningInstanceCount increase as replacement instances come up with the updated daemon.
- circuitBreaker tracks failures. If failureCount reaches the threshold (default 3), ECS automatically rolls back to the previous revision — no manual intervention needed.

Run the command a few times during the deployment to observe the drain-provision-replace cycle in action.        