<!--    Update Managed Daemons -->

The daemon task definition has been updated to increase its memory reservation and add a disk metric collector - as shown in daemon.yaml

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


<!-- *** Notes and commands *** -->

Note that the UI task definition has been updated to include pip and ipc mode in response to the new procwatch task definition that uses it to have access to system level process

# Deploy the daemon
Confirm the daemon reaches ACTIVE and is placed on your instances:

    $ aws ecs describe-daemon \
        --daemon-arn arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:daemon/${ECS_CLUSTER}/retail-store-procwatch \
        --region $AWS_REGION --no-cli-pager

# Observe namespace sharing
Because pidMode is shared, the daemon sits in the host PID namespace and can enumerate every process on the instance, including those inside your application containers. The daemon logs this count every 30 seconds.

The daemon reports ACTIVE as soon as it is created, but ECS still needs to place and start a task on each instance — this can take up to 5 minutes. Confirm a daemon task has reached RUNNING before reading the logs:

    $ TASK_ARNS=$(aws ecs list-tasks \
        --cluster $ECS_CLUSTER \
        --daemon-name retail-store-procwatch \
        --region $AWS_REGION --query 'taskArns[]' --output text)

    $ if [ -z "$TASK_ARNS" ]; then
        echo "No daemon task placed on an instance yet — wait a moment and re-run."
    else
        aws ecs describe-tasks \
            --cluster $ECS_CLUSTER \
            --tasks $TASK_ARNS \
            --query 'tasks[].lastStatus' --output text \
            --region $AWS_REGION --no-cli-pager
    fi

Once it prints RUNNING, read the daemon's logs:

    $ aws logs tail retail-store-app-ecs \
        --log-stream-name-prefix procwatch-daemon \
        --since 5m \
        --format short \
        --region $AWS_REGION

You should see output similar to:

    [procwatch] started with pidMode=shared ipcMode=shared
    [procwatch] processes visible: 115
    [procwatch] /dev/shm contents:
    [procwatch] --- top processes ---
        1 root      {systemd} /sbin/init ...
    392 root      systemd-journald
    1148 root      /usr/bin/containerd
    1185 root      /run/ecs/two
    1194 root      /usr/sbin/fmi-otelcol --config=/var/lib/two/fmi-otel.yaml
    ... more host and ECS agent processes ...
    [procwatch] --- application processes from other tasks ---
    2847 root      java -jar /app/app.jar          # the UI application container        