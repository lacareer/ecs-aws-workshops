This template uses Cloud Map DNS service discovery and not Service Connect used in the previous module

AWS::ServiceDiscovery::PrivateDnsNamespace No Service Connect sidecar: unlike the Service Connect approach, tasks here run only your application container (no ecs-service-connect-agent), so you lose the automatic Service Connect metrics — which is fine, since this module relies on Container Insights instead.

- Service Connect (what you had before) injects an Envoy sidecar proxy into every task and writes those 127.255.0.x entries into hosts. That's why you previously saw catalog, orders, etc. listed there.

- Cloud Map DNS discovery (AWS::ServiceDiscovery::Service + PrivateDnsNamespace, your v3 template) has no sidecar and no hosts injection. Instead it creates a Route 53 private hosted zone for retailstore.local, and services are resolved through real DNS (the VPC resolver), not hosts.

For service connect metric use  AWS::ServiceDiscovery::HttpNamespace instead

<!-- Service connect testing -->
Connect to the UI containiner and Install jq and dig package

    $ dnf install -y jq

    $ dnf install -y bind-utils

    $ dig +short catalog.retailstore.local
    
        10.0.5.10
    
    $ nslookup catalog.retailstore.local

        Server:         10.0.0.2
        Address:        10.0.0.2#53

        Non-authoritative answer:
        Name:   catalog.retailstore.local
        Address: 10.0.5.10    

check for dns names on UI container

    $ getent hosts catalog.retailstore.local
        
        10.0.5.10       catalog.retailstore.local  

    $ nslookup catalog.retailstore.local 2>/dev/null || dig +short catalog.retailstore.local          

Check connection from ui to catalog

    $ curl -s http://catalog.retailstore.local:8080/catalog/products | jq

        [
        {
            "id": "a1258cd2-176c-4507-ade6-746dab5ad625",
            "name": "Aqua Ace GT",
            "description": "Transform your luxury sports car into a high-speed submarine with the push of a button. Features hydro-jet propulsion, underwater navigation, and oxygen recycling system for up to 8 hours. Includes coral-proof paint coating.",
            "price": 10000,
            "tags": [
            {
                "name": "vehicles",
                "displayName": "Vehicles"
            }
            ]
        },
        {
            "id": "d4edfedb-dbe9-4dd9-aae8-009489394955",
            "name": "Audio-Illusion Spinner",
            "description": "Professional-grade sonic illusion generator disguised as a simple yo-yo. Creates realistic sound effects from footsteps to full orchestras. Includes comprehensive training manual and anti-tangle technology.",
            "price": 190,
            "tags": [
            {
                "name": "accessories",
                "displayName": "Accessories"
            }
            ]
        },
        {
        ...
        ...
        ... 


    $ curl -s http://orders.retailstore.local:8080/actuator/health

        {"status":"UP"}

    $ sh-5.2# curl -s http://checkout.retailstore.local:8080/health

        {"status":"ok","info":{"chaos":{"status":"up"}},"error":{},"details":{"chaos":{"status":"up"}}}

    $ curl -s http://carts.retailstore.local:8080/actuator/health

        {"status":"UP"}



<!-- Generate traffic to see logs -->

Follow pdf to generate traffic and view container insights
