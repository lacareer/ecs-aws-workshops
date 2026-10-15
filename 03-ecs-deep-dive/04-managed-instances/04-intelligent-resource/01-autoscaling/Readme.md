<!-- Lab commands for load testing-->
First, verify the DNS name for the load balancer associated with the UI service. This environment variable should have been exported during the fundamental chapter.

    $ echo http://${ALB_URL} ; echo

Use the hey tool  to send requests to the /home path of the UI service:

    $ hey -n 1000000 -c 5 -q 40 http://$ALB_URL/home &    

Scaling activity triggers when the AlarmHigh breaches for 3 consecutive 1-minute periods. To automatically wait for the alarm to trigger, run this command (~ 4 min):

    $ sleep 90 && aws cloudwatch wait alarm-exists --alarm-name-prefix \
        TargetTracking-service/retail-store-ecs-cluster/ui-AlarmHigh --state-value ALARM   

When the alarm fires, you'll see the service's task count increase from 2:

    $ aws ecs describe-tasks \
        --cluster retail-store-ecs-cluster \
        --tasks $(aws ecs list-tasks --cluster retail-store-ecs-cluster --service ui --query 'taskArns[]' --output text) \
        --query "tasks[*].[group, launchType, lastStatus, healthStatus, taskArn]" --output table         

o stop the hey process, run:

    $ pkill -9 hey        

Usually, the number of tasks will scale back to the minimum of 2 after several minutes. To expedite this process, force the service to scale down with these commands:

    $ aws ecs update-service \
        --cluster retail-store-ecs-cluster \
        --service ui \
        --task-definition retail-store-ecs-ui \
        --desired-count 2 \
        --no-cli-pager

    $ aws ecs wait services-stable --cluster retail-store-ecs-cluster --services ui    