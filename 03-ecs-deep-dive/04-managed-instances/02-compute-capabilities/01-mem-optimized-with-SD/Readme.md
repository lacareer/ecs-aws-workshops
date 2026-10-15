<!--    Managed Instance memory optimized with Service discovery -->

Continuation of the previous lab

*** Note ***

- Updated the task role to include permission for DDB

- Added some new resources to template for cart service and added Service discovery

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

<!-- Testing Service Discovery -->
The UI task should be able to reach the Cart service now on service discovery using cloud map

Exec into the UI task (you already have the command in your Readme), then:


    $ sh-5.2# getent hosts carts.retailstore.local

        10.0.3.234      carts.retailstore.local

    $ sh-5.2# nslookup carts.retailstore.local [install nslookup utility in task/container if you want command to work]

        sh: nslookup: command not found

    $ sh-5.2# dig +short carts.retailstore.local [install dig utility in task/container if you want command to work]

        sh: dig: command not found

    $ sh-5.2# curl -v http://carts.retailstore.local:8080/actuator/health

    * Host carts.retailstore.local:8080 was resolved.
    * IPv6: (none)
    * IPv4: 10.0.3.234
    *   Trying 10.0.3.234:8080...
    * Connected to carts.retailstore.local (10.0.3.234) port 8080
    * using HTTP/1.x
    > GET /actuator/health HTTP/1.1
    > Host: carts.retailstore.local:8080
    > User-Agent: curl/8.11.1
    > Accept: */*
    > 
    * Request completely sent off
    < HTTP/1.1 200 
    < Content-Type: application/vnd.spring-boot.actuator.v3+json
    < Transfer-Encoding: chunked
    < Date: Thu, 01 Oct 2026 01:21:04 GMT
    < 
    * Connection #0 to host carts.retailstore.local left intact
    {"status":"UP"}sh-5.2# 




