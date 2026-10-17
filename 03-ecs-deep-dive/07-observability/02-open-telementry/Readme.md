NOTE THAT THE CART SERVICE WAS NOT DEPLOYED IN THIS MODULE BUT THE CART STILL WORKS
THERE MUST BE SOMETHING ON THECODE SIDE FOR THIS REASON

REFER TO 01-ecs-express-mode/cloudformation/02-frontend-backend/express-mode.yaml or 03-ecs-deep-dive/06-networking/03-vpc-lattice TO SEE CART DDB AND SERVICE DEPLOYMENT


# FOR MORE SERVICE CONNECT EXAMPLES,TESTING SERVICE TO SERVICE CONNECTION, AND DIFFERENCE BETWEEN SERVICE CONNECT AND CLOUDMAPS:

- 03-ecs-deep-dive/04-managed-instances/02-compute-capabilities/01-mem-optimized-with-SD/managed-instances.yaml [cloudmap sample ]

- 03-ecs-deep-dive/04-managed-instances/05-service-connect/01-service-connect/service-connect-v1.yaml [service connect]

- 03-ecs-deep-dive/04-managed-instances/05-service-connect/01-service-connect/service-connect-v2.yaml [service connect sample]

- 03-ecs-deep-dive/04-managed-instances/06-observability/cloudmap-v3.yaml [cloudmap sample]

- Make sure to read the README files for each folder to see the difference between AWS::ServiceDiscovery::HttpNamespace and AWS::ServiceDiscovery::PrivateDnsNamespace with how they are defined

<!-- Notes -->
# Notes / caveats

- Task role vs execution role: the AWSOpenTelemetryPolicy goes on the task role (what the collector process assumes), not the execution role. I attached it to the four task roles above.

- OTEL_JAVA_* is Java-only: UI, orders, catalog are Java/Spring (auto-instrumented already, per the lab). Checkout is Node.js — the Java vars are harmless but you can drop them there; the OTLP endpoint + service name are what matter.

- Port 4318 is OTLP/HTTP; the collector also listens on 4317 (gRPC). The app talks to localhost:4318 because both containers share the task's network namespace (awsvpc).

- No SG changes — collector traffic is intra-task over localhost; it egresses to X-Ray/CloudWatch over the existing -1 egress rule.

- EMF metrics land in CloudWatch namespace ECS/AWSOTel/Application and log group /aws/ecs/application/metrics (created by the collector via the task-role permissions) 

— that's what page 400 queries.

