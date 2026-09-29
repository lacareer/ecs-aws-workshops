<!-- Deployment -->
Deploy the resource in this order:

1. Deploy the VPC in pre-req/one-vpc.yaml

2. Wait for item 1 deploment to complete successfully

3. Deploy 02-ecs-3-tier-architecture/03-autoscaling-on-traffic/autoscaling.yaml

4. Wait for all the services [ui, order, catalog, checkout, and cart] the deploment to complete successfully

5. Once completed, got to the AWS Console and copy the ALB url

6. Prefix it with http://<ALB_URL>, paste in a browser and hit enter. You should see the running UI App

<!-- Stress testing -->
We use the package 'hey' for stress testing: https://github.com/rakyll/hey
***Hey Installation***
    $ curl --output hey  https://storage.googleapis.com/hey-releases/hey_linux_amd64 [downloads package into a file I called hey in my user/home directory]

    $ chmod u+x hey [makes it executable]

    $ sudo mv hey /usr/local/bin/hey [Move the downloaded binary to where binary are and run from]

    $ hey https://google.com [test hey with default to confirm it works]

        Summary:
        Total:        0.8528 secs
        Slowest:      0.4321 secs
        Fastest:      0.1118 secs
        Average:      0.1844 secs
        Requests/sec: 234.5209
        

        Response time histogram:
        0.112 [1]     |
        0.144 [122]   |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
        0.176 [24]    |■■■■■■■■
        0.208 [2]     |■
        0.240 [1]     |
        0.272 [2]     |■
        0.304 [4]     |■
        0.336 [13]    |■■■■
        0.368 [27]    |■■■■■■■■■
        0.400 [3]     |■
        0.432 [1]     |


        Latency distribution:
        10%% in 0.1200 secs
        25%% in 0.1254 secs
        50%% in 0.1365 secs
        75%% in 0.2606 secs
        90%% in 0.3450 secs
        95%% in 0.3579 secs
        99%% in 0.3691 secs

        Details (average, fastest, slowest):
        DNS+dialup:   0.0176 secs, 0.0000 secs, 0.0948 secs
        DNS-lookup:   0.0041 secs, 0.0000 secs, 0.0459 secs
        req write:    0.0026 secs, 0.0000 secs, 0.0364 secs
        resp wait:    0.0816 secs, 0.0656 secs, 0.1966 secs
        resp read:    0.0137 secs, 0.0011 secs, 0.0509 secs

        Status code distribution:
        [200] 200 responses

*** commands ***

<!-- Trigger Auto Scaling -->
In this section, we'll generate synthetic load for our UI service to observe its scaling behavior.

First, verify the DNS name for the load balancer associated with our UI service. This environment variable should have been exported as part of the fundamental chapter.

    $ export RETAIL_ALB=$(aws elbv2 describe-load-balancers --name retail-store-alb \
        --query 'LoadBalancers[0].DNSName' --output text)
    
    $ echo_c ${RETAIL_ALB}

Next, we'll use the hey tool  to send requests to the /home path of the UI service:

    $ hey -n 1000000 -c 5 -q 40 http://$RETAIL_ALB/home &

Scaling activity will be triggered when the high alarm for the scaling metric breaches for 3 consecutive 1-minute periods. If you want to automatically wait until the alarm triggers, you can run this command (~ 4 min):

    $ sleep 90 && aws cloudwatch wait alarm-exists --alarm-name-prefix \
      TargetTracking-service/retail-store-ecs-cluster/ui-AlarmHigh --state-value ALARM

When the alarm fires, you'll notice the service's task count scaling out from 2 to a higher number:

    $ aws ecs describe-tasks \
        --cluster retail-store-ecs-cluster \
        --tasks $(aws ecs list-tasks --cluster retail-store-ecs-cluster --query 'taskArns[]' --output text) \
        --query "tasks[*].[group, launchType, lastStatus, healthStatus, taskArn]" --output table

You can observe the associated high alarm with the scaling policy transitioning to the ALARM state in the CloudWatch console, as shown below.

To stop the hey process, run the following command:

    $ pkill -9 hey

Normally, after several minutes, the number of tasks should scale back to the minimum of 2. However, for the sake of time, we can force the service to scale down by running the following commands:

    $ echo_y "Waiting for service to stabilize..."

    $ aws ecs wait services-stable --cluster retail-store-ecs-cluster --services ui

    $ aws ecs update-service \
        --cluster retail-store-ecs-cluster \
        --service ui \
        --task-definition retail-store-ecs-ui \
        --desired-count 2