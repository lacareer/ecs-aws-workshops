<!--    Managed Instance with EFS -->

Continuation of the previous lab

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


*** Note to see images on page ***
Template did not deploy successfully even though all resources but the ECS Service were created successfully.

This is just a an SCP from PluralSight that restricts Neuron Inference instances by users. 

Error resulting from too much memory usage or similar to what is shown below:

    service was unable to place a task. Reason: ResourceInitializationError: Unable to launch instance(s) for capacity provider gpu-nvidia-cp. 
    UnauthorizedOperation: You are not authorized to perform this operation. 
    User: arn:aws:sts::671280668880:assumed-role/ecsManagedInstancesInfrastructureRole/ECSManagedInstances is not authorized to perform: ec2:RunInstances on resource: arn:aws:ec2:us-east-1:671280668880:instance/* with an explicit deny in a service control policy: arn:aws:organizations::674998908974:policy/o-yu55c2titn/service_control_policy/p-cr6s9vs4. RequestId: e443de38-2087-4a9e-9815-2af44997e8c2.
