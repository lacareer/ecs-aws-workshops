NOTE THAT THE CART SERVICE WAS NOT DEPLOYED IN THIS MODULE BUT THE CART STILL WORKS
THERE MUST BE SOMETHING ON THECODE SIDE FOR THIS REASON


ALSO, WHEN A STACK THAT HAS SERVICE CONNECT IS DELETED, THE NAMESPACE IS NOT. GO TO AWS CLOUD MAP, FIND THE NAMESPACE, AND DELETE. 
THIS DELETES IT COMPLETELY AND IT IS NO LONGER VISIBLE BOTH IN CLOUD MAP NOR ECS -> NAMESPACE

<!-- Deployment -->
Deploy the resource in this order:

1. Deploy the VPC in pre-req/one-vpc.yaml

2. Wait for item 1 deploment to complete successfully

3. Deploy 02-ecs-3-tier-architecture/02-fe-be-service-connect

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

<!-- Get ALB endpoint and send traffic to ui service/container -->

    $ export RETAIL_ALB=$(aws elbv2 describe-load-balancers --name retail-store-ecs-ui \
        --query 'LoadBalancers[0].DNSName' --output text)

    $ hey -n 1000000 -c 1 -q 10 http://$RETAIL_ALB/home &

    $ pkill -9 hey

<!-- Connect to the ECS Task -->
Execute the following command to select one of the running tasks with enableExecuteCommand enabled:

    $ ECS_EXEC_TASK_ARN=$(aws ecs list-tasks --cluster retail-store-ecs-cluster \
        --service-name ui --query 'taskArns[]' --output text | \
        xargs -n1 aws ecs describe-tasks --cluster retail-store-ecs-cluster --tasks | \
        jq -r '.tasks[] | select(.enableExecuteCommand == true) | .taskArn' | \
        head -n 1)

    $ echo_g $ECS_EXEC_TASK_ARN

This will output the ARN of the task:

    arn:aws:ecs:us-west-2:XXXXXXXXXX:task/retail-store-ecs-cluster/0564778486a846599b8bd6b544e5f6eb

Now, start a /bin/bash interactive session in the running task:

    $ if [ -z "${ECS_EXEC_TASK_ARN}" ]; then echo_y "ECS_EXEC_TASK_ARN is not correctly configured!"; else

    $ aws ecs execute-command --cluster retail-store-ecs-cluster \
        --task $ECS_EXEC_TASK_ARN \
        --container application \
        --interactive \
        --command "/bin/bash"
    fi    

<!-- Setup environment -->
In the Bash shell, install the jq command on the running container to format JSON output:

    $ dnf install jq -y    

<!-- Explore the host UI file -->
The /etc/hosts file provides mapping of fully qualified domain names (FQDNs) to their respective IP addresses. Review the /etc/hosts file content by running the following command:

    $ cat /etc/hosts

        bash-5.2# cat /etc/hosts
        127.0.0.1 localhost
        10.0.3.111 ip-10-0-3-111.ec2.internal
        127.255.0.1 catalog
        2600:f0f0:0:0:0:0:0:1 catalog
        127.255.0.2 checkout
        2600:f0f0:0:0:0:0:0:2 checkout
        127.255.0.3 orders
        2600:f0f0:0:0:0:0:0:3 orders
        127.255.0.4 ui
        2600:f0f0:0:0:0:0:0:4 ui

The file contains three Discovery names set up in the ECS Namespace with different local IPs 127.255.0.X (IPv4 and IPv6). These local IPs all point to the same ECS local proxy, which redirects traffic to the appropriate ECS remote proxy bound to the specific service.

<!-- Test the connection to the Catalog service -->
Test the connection to the Catalog service by retrieving the product list from the Catalog API. We perform the request with the verbose option (-v) to review header information.

    $ curl -v -s http://catalog/catalog/products | jq

Below is the product list with highlighted envoy proxy headers.


    * Host catalog:80 was resolved.
    * IPv6: 2600:f0f0::1
    * IPv4: 127.255.0.1
    *   Trying [2600:f0f0::1]:80...
    * Immediate connect fail for 2600:f0f0::1: Network is unreachable
    *   Trying 127.255.0.1:80...
    * Connected to catalog (127.255.0.1) port 80
    * using HTTP/1.x
    > GET /catalog/products HTTP/1.1
    > Host: catalog
    > User-Agent: curl/8.11.1
    > Accept: */*
    > 
    * Request completely sent off
    < HTTP/1.1 200 OK
    < content-type: application/json; charset=utf-8
    < date: Mon, 25 Aug 2025 23:42:22 GMT
    < x-envoy-upstream-service-time: 10
    < server: envoy
    < transfer-encoding: chunked
    < 
    { [3730 bytes data]
    * Connection #0 to host catalog left intact

    [
        {
            "id":"a1258cd2-176c-4507-ade6-746dab5ad625",
            "name":"Aqua Ace GT",
            "description":"Transform your luxury sports car into a high-speed submarine with the push of a button. Features hydro-jet propulsion, underwater navigation, and oxygen recycling system for up to 8 hours. Includes coral-proof paint coating.",
            "price":10000,
            "tags":[
                {
                    "name":"vehicles",
                    "displayName":"Vehicles"
                }
            ]
        },
        {
    ...
    ...
    ...
    ...            

To terminate your exec session, run:

    $ exit    

<!-- See Attached ECS Lab Doc on how to test ECS Service Connect Retry Capabilities     -->