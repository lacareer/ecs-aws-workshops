# Read docs for more info

<!-- Task Execution Role -->
The task execution role grants the Amazon ECS container agent permission to call specific AWS API actions on your behalf. For instance, AWS Fargate requires an IAM role that allows it to pull images from Amazon ECR and write logs to CloudWatch Logs. An IAM role is also necessary when a task references a secret stored in AWS Secrets Manager, such as an image pull secret.

<!-- Task IAM role -->
This role allows your application code (within the container) to access other AWS services. It's recommended to assign each task an IAM role, which aligns with the principle of least privileged access and enables more granular control over actions and resources.

When assigning IAM roles to a task, you must use the following trust policy. This ensures that each task can assume an IAM role distinct from the one used by the EC2 instance it's running on, preventing the task from inheriting the EC2 instance's role:

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

