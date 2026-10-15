<!-- lab consolidation commands -->

Wait for services to stabilize and check initial instance count:

# Wait for services to be stable
    $ aws ecs wait services-stable \
    --cluster retail-store-ecs-cluster \
    --services consolidation-test-1 consolidation-test-2

# Check current instance count for our capacity provider
    $ echo "Initial instance count for consolidation-test-cp:"
    $ INSTANCE_ARNS=$(aws ecs list-container-instances --cluster retail-store-ecs-cluster --query 'containerInstanceArns[]' --output text)
    $ aws ecs describe-container-instances --cluster retail-store-ecs-cluster --container-instances $INSTANCE_ARNS --query 'containerInstances[?capacityProviderName==`consolidation-test-cp`].containerInstanceArn' --output text | wc -w

# Show task distribution across instances
    $ echo "Task distribution:"
    $ INSTANCE_ARNS=$(aws ecs list-container-instances --cluster retail-store-ecs-cluster --query 'containerInstanceArns[]' --output text)
    $ aws ecs describe-container-instances --cluster retail-store-ecs-cluster --container-instances $INSTANCE_ARNS --query 'containerInstances[?capacityProviderName==`consolidation-test-cp`].containerInstanceArn' --output table

Now let's trigger consolidation by scaling down the services:

# Scale down both services to trigger consolidation
    $ aws ecs update-service \
        --cluster retail-store-ecs-cluster \
        --service consolidation-test-1 \
        --desired-count 1 --no-cli-pager

    $ aws ecs update-service \
        --cluster retail-store-ecs-cluster \
        --service consolidation-test-2 \
        --desired-count 1 --no-cli-pager

    $ echo "Scaled down services. Waiting for consolidation to occur..."

Monitor the consolidation process:    

# Wait for services to stabilize after scale-down
    $ aws ecs wait services-stable \
        --cluster retail-store-ecs-cluster \
        --services consolidation-test-1 consolidation-test-2

# Check instance count after consolidation for our capacity provider
    $ echo "Instance count after consolidation for consolidation-test-cp:"
    $ INSTANCE_ARNS=$(aws ecs list-container-instances --cluster retail-store-ecs-cluster --query 'containerInstanceArns[]' --output text)
    $ aws ecs describe-container-instances --cluster retail-store-ecs-cluster --container-instances $INSTANCE_ARNS --query 'containerInstances[?capacityProviderName==`consolidation-test-cp`].containerInstanceArn' --output text | wc -w

# Show remaining tasks and their placement
    $ echo "Remaining tasks after consolidation:"
    $ for service in consolidation-test-1 consolidation-test-2; do
        echo "Service: $service"
        TASK_ARNS=$(aws ecs list-tasks --cluster retail-store-ecs-cluster --service-name $service --query 'taskArns[]' --output text)
        for task in $TASK_ARNS; do
            aws ecs describe-tasks --cluster retail-store-ecs-cluster --tasks $task --query 'tasks[0].{TaskArn:taskArn,ContainerInstance:containerInstanceArn}' --output table
        done
    done

Clean up test resources:

# Delete test services
$ aws ecs delete-service --cluster retail-store-ecs-cluster --service consolidation-test-1 --force --no-cli-pager
$ aws ecs delete-service --cluster retail-store-ecs-cluster --service consolidation-test-2 --force --no-cli-pager

# Wait for services to be deleted
$ aws ecs wait services-inactive --cluster retail-store-ecs-cluster --services consolidation-test-1 consolidation-test-2

$ echo "Consolidation test completed. ECS Managed Instances automatically consolidated workloads onto fewer instances, reducing costs while maintaining service availability."