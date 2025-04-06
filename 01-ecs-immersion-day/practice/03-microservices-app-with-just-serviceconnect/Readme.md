<!-- NOTE -->
I used the AWS Nginx publuc image in ECR image. Allso nsome of the resources use/hardcoded her was taken from the previous labs, like:

ECS_SG_ID="sg-0f1ea858b0b0b5478"

PRIVATE_SUBNET1="subnet-0966d0570f9f4ba4b"

PRIVATE_SUBNET2="subnet-0343eaef6ad4d3d19"

ECS_EXECUTION_ROLE="arn:aws:iam::066638479762:role/ecs-execution-role"

ECS_TASK_ROLE="arn:aws:iam::066638479762:role/ecs-task-role"

MY_VPC="vpc-08b0317de67c51e8a"

<!-- Create Cluster and Service Connect Namespace-->
***Make sure the namespace and the cluster name match, otherwise connectivity between containers tend to fail.***
***I don't know why bcs I could not find a doc as to why but realized it after much troubleshooting for days***

Create an Amazon ECS cluster named nginx_cluster to use. The parameter --service-connect-defaults sets the default namespace of the cluster. In the example output, a AWS Cloud Map namespace of the name nginx_service_connect doesn't exist in this account and AWS Region, so the namespace is created by Amazon ECS. The namespace is made in AWS Cloud Map in the account, and is visible with all of the other namespaces, so use a name that indicates the purpose.

-$ aws ecs create-cluster --cluster-name nginx_cluster --service-connect-defaults namespace=nginx_cluster --region us-east-1

Output similar to:

{
    "cluster": {
        "clusterArn": "arn:aws:ecs:us-west-2:123456789012:cluster/tutorial",
        "clusterName": "tutorial",
        "serviceConnectDefaults": {
            "namespace": "arn:aws:servicediscovery:us-west-2:123456789012:namespace/ns-EXAMPLE"
        },
        "status": "PROVISIONING",
        ....
        ....
        ....
    }
}

Verify that the cluster is created:

-$ aws ecs describe-clusters --clusters nginx_cluster

Output similar to:

{
    "clusters": [
        {
            "clusterArn": "arn:aws:ecs:us-west-2:123456789012:cluster/tutorial",
            "clusterName": "tutorial",
            "serviceConnectDefaults": {
                "namespace": "arn:aws:servicediscovery:us-west-2:123456789012:namespace/ns-EXAMPLE"
            },
        ....
        ....
        ....
        }
    ]
}

Verify that the namespace is created in AWS Cloud Map. You can use the AWS Management Console or the normal AWS CLI configuration as this is created in AWS Cloud Map.

For example, use the AWS CLI:

-$ aws servicediscovery get-namespace --id ns-4lszj37wrovwu2to

Output similar to below:

{
    "Namespace": {
        "Id": "ns-EXAMPLE",
        "Arn": "arn:aws:servicediscovery:us-west-2:123456789012:namespace/ns-EXAMPLE",
        "Name": "service-connect",
        "Type": "HTTP",
        ...
        ...
        ...
    }
}

<!--  Create task definitions -->

Create the nginx_1 and nginx_2 task definitions:

-$ aws ecs register-task-definition --cli-input-json file://nginx_1_taskdef.json --region us-east-1

-$ aws ecs register-task-definition --cli-input-json file://nginx_2_taskdef.json --region us-east-1

<!-- Create services --> 

The service configs files don't contain the created namespace because when we created the cluster we asked it to use the namespace as it's default. So, every service in the cluster can use the name space by referencing the cluster name.

Create the nginx_1_service and nginx_2_service:

-$ aws ecs create-service --cluster nginx_cluster --cli-input-json file://nginx_1_service.json --region us-east-1

-$ aws ecs create-service --cluster nginx_cluster --cli-input-json file://nginx_2_service.json --region us-east-1

<!-- EXEC into task -->

To exec into an ecs task, we run:

    aws ecs execute-command --cluster nginx_cluster --task yourTaskARN --container theTaskContainerInTaskDef --interactive --command "/bin/bash"

In our case to exec into one of our nginx_1 task container, we run:

-$ aws ecs execute-command --cluster nginx_cluster --task arn:aws:ecs:us-east-1:066638479762:task/nginx_cluster/5c9a5f4f9acd478897bfeff5a31f5a48 --container nginx_1 --interactive --command "/bin/bash" --region us-east-1

***Note (If the containers were deployed in parallel, the /etc/hosts file might not have been updated correctly for the second container. Redeploying the affected container with --force-new-deployment can refresh the /etc/hosts entries to show all containers and their dns names)***

root@ip-10-0-3-187:/# cat /etc/hosts

root@ip-10-0-3-187:/# cat /usr/share/nginx/html/index.html

root@ip-10-0-3-187:/# sed -i 's/nginx/nginx_1/g' /usr/share/nginx/html/index.html

root@ip-10-0-3-187:/# cat /usr/share/nginx/html/index.html


In our case to exec into one of our nginx_2 task container, we run:

-$ aws ecs execute-command --cluster nginx_cluster --task arn:aws:ecs:us-east-1:066638479762:task/nginx_cluster/b3b3a6eea7bb4d2c8e2587c7f010bb87 --container nginx_2 --interactive --command "/bin/bash" --region us-east-1

***Note (If the containers were deployed in parallel, the /etc/hosts file might not have been updated correctly for the second container. Redeploying the affected container with --force-new-deployment can refresh the /etc/hosts entries to show all containers and their dns names)***

root@ip-10-0-2-52:/# cat /etc/hosts

root@ip-10-0-2-52:/# cat /usr/share/nginx/html/index.html

root@ip-10-0-2-52:/# sed -i 's/nginx/nginx_2/g' /usr/share/nginx/html/index.html

root@ip-10-0-2-52:/# cat /usr/share/nginx/html/index.html

<!-- Test nginx_1 connectivity to nginx_2 -->

Test connectivity from nginx_1 container to container nginx_2

    root@ip-10-0-3-187:/# curl http://nginx_2:80

Should return nginx_2 html page below:

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx_2!</title>
...
...
</head>
</html>


<!-- Test nginx_1 connectivity to nginx_2 -->

Test connectivity from nginx_2 container to container nginx_1

    root@ip-10-0-2-52:/# curl http://nginx_1:80

Should return nginx_2 html page below:

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx_1!</title>
...
...
</head>
</html>