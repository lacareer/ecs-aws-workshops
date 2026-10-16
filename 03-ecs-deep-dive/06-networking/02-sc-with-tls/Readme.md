This lab is a continuation of 01-service-connect/fe-be-sc.yaml

<!-- Notes -->

Try deploy in our own account since Stack failed because of the PluralSight SCP error below:

	
Resource handler returned message: "User: arn:aws:iam::525357906292:user/cloud_user is not authorized to perform: acm-pca:CreateCertificateAuthority on resource: arn:aws:acm-pca:us-east-1:525357906292:certificate-authority/* because no service control policy allows the acm-pca:CreateCertificateAuthority action (Service: AWSPrivateCA; Status Code: 400; Error Code: AccessDeniedException; Request ID: 76a1b23c-ff76-44c5-b23b-44df9644bf8e; Proxy: null)" (RequestToken: 5feb6204-343d-65e0-ecf2-12a028b213bf, HandlerErrorCode: AccessDenied)