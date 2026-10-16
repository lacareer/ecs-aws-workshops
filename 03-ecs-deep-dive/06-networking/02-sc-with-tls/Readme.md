This lab is a continuation of 01-service-connect/fe-be-sc.yaml

<!-- Notes -->

Try deploy in our own account since Stack failed because of the PluralSight SCP error below:

	
Resource handler returned message: "User: arn:aws:iam::525357906292:user/cloud_user is not authorized to perform: acm-pca:CreateCertificateAuthority on resource: arn:aws:acm-pca:us-east-1:525357906292:certificate-authority/* because no service control policy allows the acm-pca:CreateCertificateAuthority action (Service: AWSPrivateCA; Status Code: 400; Error Code: AccessDeniedException; Request ID: 76a1b23c-ff76-44c5-b23b-44df9644bf8e; Proxy: null)" (RequestToken: 5feb6204-343d-65e0-ecf2-12a028b213bf, HandlerErrorCode: AccessDenied)

I deployed itin my personal account and it was successful when I passed my domain a name that I own in the account

# Note: 

-  This AlbTlsCertificate is only for browser→ALB HTTPS 

-  With *.<DYOUR_DOMAIN_NAME> in AlbTlsCertificate (or any name that doesn't match the ALB's *.elb.amazonaws.com DNS), the browser shows a name-mismatch + untrusted-CA warning. 
  
  That's the same "click Advanced → Proceed (unsafe)" experience the workshop already warns about, so it's acceptable for the lab.

  To avoid this, create a R53 record that points to the ALB and use it to access the UI page on HTTPS and the browser warning will go away because the url is now part of the *<domainName>

# it's independent of the Service Connect mesh TLS (which uses the private CA directly via each service's Tls block and is unaffected by this error).

# Service connect creates and manages its own TLS certificates automatically.

# creation, rotation, and revocation are handled by the service itself once a service is deployed with TLS enabled.

<!-- TLS Verification -->

  $ export ECS_EXEC_TASK_ARN=$(aws ecs list-tasks --cluster retail-store-ecs-cluster \
      --service-name ui --query 'taskArns[0]' --output text | \
      xargs -n1 aws ecs describe-tasks --cluster retail-store-ecs-cluster --tasks | \
      jq -r '.tasks[] | select(.enableExecuteCommand == true) | .taskArn' | \
      head -n 1)

  $ echo ${ECS_EXEC_TASK_ARN}

Earlier on the verification page, you run this (from the IDE, before you exec in), which writes the file inside the UI task:

  $ aws ecs execute-command --cluster retail-store-ecs-cluster \
      --task $ECS_EXEC_TASK_ARN \
      --container application \
      --interactive \
      --command "/bin/bash -c 'echo UI_TLS_PRIVATE_IP=$(echo $UI_TLS_PRIVATE_IP) > /app/private_ip.env'"


That command redirects UI_TLS_PRIVATE_IP=<ip> into /app/private_ip.env on the container. So its entire content is one line, e.g.:

  $ UI_TLS_PRIVATE_IP=10.0.3.57 

  $ task_arn=$(aws ecs list-tasks --cluster retail-store-ecs-cluster --service-name ui --query 'taskArns[0]' --output text)

  $ UI_TLS_PRIVATE_IP=$(aws ecs describe-tasks --cluster retail-store-ecs-cluster --tasks $task_arn \
      | jq -r '.tasks[].containers[] | select(.name=="application") | .networkInterfaces[0].privateIpv4Address')  

  # get a catalog task private IP
  $ task_arn=$(aws ecs list-tasks --cluster retail-store-ecs-cluster --service-name catalog --query 'taskArns[0]' --output text)

  $ CATALOG_PRIVATE_IP=$(aws ecs describe-tasks --cluster retail-store-ecs-cluster --tasks $task_arn \
    | jq -r '.tasks[].containers[] | select(.name=="application") | .networkInterfaces[0].privateIpv4Address')
  
  # then from inside any task that can reach it:
  openssl s_client -connect $CATALOG_PRIVATE_IP:8080 </dev/null 2>/dev/null | openssl x509 -noout -text           


