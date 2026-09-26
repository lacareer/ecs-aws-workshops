<!-- Explanation of cfn template -->

Let’s break this down to understand what we are deploying. In the snippet below we are creating two capacity providers that take advantage of the managed cluster autoscaling (as seen by ManagedScaling being ENABLED). to We are referencing the autoscaling groups that we created in the template just above.

  CapacityProvider1:
    Type: "AWS::ECS::CapacityProvider"
    Properties:
      AutoScalingGroupProvider:
        AutoScalingGroupArn: !Ref AutoScalingGroup1
        ManagedScaling:
          Status: ENABLED
        ManagedTerminationProtection: ENABLED
  CapacityProvider2:
    Type: "AWS::ECS::CapacityProvider"
    Properties:
      AutoScalingGroupProvider:
        AutoScalingGroupArn: !Ref AutoScalingGroup2
        ManagedScaling:
          Status: ENABLED
        ManagedTerminationProtection: ENABLED

Next, we will create an ECS cluster, and then associate the capacity providers with that cluster. The two capacity providers that we are setting as the default for the cluster are available “out of the box” and are FARGATE and FARGATE_SPOT. Next, we set the default capacity provider strategy for our cluster, which will determine how tasks get placed that aren’t launched with a launch type or capacity provider strategy specified. This goes back to the “application first” mindset, where those who are deploying their tasks/services don’t have to think about compute capacity, and can simply define how they want their containers to run in the task definition and service configuration. Finally, you may notice the base and weight for each of the capacity providers. In the example template, we ensure that we always have one on demand Fargate task running for baseline stability, with every task launched after the base using Fargate Spot. Finally, we are attaching the two autoscaling group-backed capacity providers to the cluster that we discussed up above.

  ECSCluster:
    Type: 'AWS::ECS::Cluster'

  ClusterCPAssociation:
    Type: "AWS::ECS::ClusterCapacityProviderAssociations"
    Properties:
      Cluster: !Ref ECSCluster
      CapacityProviders:
        - FARGATE
        - FARGATE_SPOT
        - !Ref CapacityProvider1
        - !Ref CapacityProvider2
      DefaultCapacityProviderStrategy:
          - CapacityProvider: FARGATE
            Base: 1
            Weight: 0
          - CapacityProvider: FARGATE_SPOT
            Weight: 1

The outcome of this deployment will provide an ECS cluster with all of the capacity providers associated as expected. In the autoscaling groups that we created in the template, we set the desired count to a minimum and a base of zero, ensuring that EC2 instances will only get launched when needed and not sit idle. This just highlights one of the many powerful features that come with capacity providers.

Now that we have our capacity providers created and associated with our cluster, let’s look at an example service deployment where we want to set the capacity providers instead of relying on the cluster default.          

  ECSTaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      RequiresCompatibilities:
        - "EC2"
      Cpu: '512'
      Memory: '1024'
      ContainerDefinitions:
        - Name: "CapacityProvidersDemo"
          Image: public.ecr.aws/nginx/nginx:latest
          PortMappings:
            - ContainerPort: 80
  ECSDemoService: 
    Type: AWS::ECS::Service
    Properties: 
      Cluster: !Ref ECSCluster
      DesiredCount: 10
      TaskDefinition: !Ref ECSTaskDefinition
      CapacityProviderStrategy:
        - CapacityProvider: !Ref CapacityProvider1
          Base: 1
          Weight: 1
        - CapacityProvider: !Ref CapacityProvider2
          Weight: 1

In the example above, we explicitly set our capacity provider strategy. As mentioned earlier, you don’t have to do this if you have a default strategy set for your cluster. It’s important to understand that when you rely on the default, you have to ensure that your task definiton and service definition are compatible with the compute being used. Assuming we didn’t set a launch type or capacity provider strategy in our service definition, in this scenario the cluster will choose the default capacity provider strategy for compute. As we saw earlier, the default capacity provider strategies for the cluster are to split across running Fargate and Fargate Spot, so after the base strategy of 1 is met for Fargate, the rest of the tasks will be launched using Fargate Spot.     

<!-- Capacity providers with blue/green deployments -->
In addition to improving our CloudFormation coverage with capacity providers, we recently announced capacity provider support when using the AWS CodeDeploy deployment controller with ECS. This means that regardless of the compute options you choose as your capacity provider strategy, you can use the CodeDeploy deployment controller. For customers using EC2 for the underlying compute with capacity providers (with cluster autoscaling enabled), you don’t have to worry about the scaling of the underlying infrastructure during a deploy. In other words, if there is not enough EC2 capacity to support the deployment, capacity providers will scale the instances to meet the need and then scale them back in.

<!-- Cluster auto scaling improvements -->
In addition to CloudFormation support and blue/green deployments via AWS CodeDeploy with capacity providers, we also added some enhancements to cluster autoscaling. For a deep dive into how cluster autoscaling works with Amazon ECS, check out the Deep Dive on Amazon ECS Cluster Auto Scaling (https://aws.amazon.com/blogs/containers/deep-dive-on-amazon-ecs-cluster-auto-scaling/).