<!-- Service connect testing -->
Connect to the UI containiner and Install jq package

    $ dnf install -y jq

check for dns names on UI container

    $ cat /etc/hosts

        127.0.0.1 localhost
        10.0.1.178 ip-10-0-1-178.ec2.internal
        127.255.0.1 carts
        2600:f0f0:0:0:0:0:0:1 carts
        127.255.0.2 catalog
        2600:f0f0:0:0:0:0:0:2 catalog
        127.255.0.3 checkout
        2600:f0f0:0:0:0:0:0:3 checkout
        127.255.0.4 orders
        2600:f0f0:0:0:0:0:0:4 orders
        127.255.0.5 ui
        2600:f0f0:0:0:0:0:0:5 ui    

Check connection from ui to catalog

    $ curl -s http://catalog:8080/catalog/products | jq

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
            ...
            ...

Check container health endpoints:

    $ curl -s http://catalog:8080/health
    
        OK

    $ curl -s http://carts:8080/actuator/health

        {"status":"UP"}

    $ curl -s http://orders:8080/actuator/health

        {"status":"UP"}

    $ curl -s http://checkout:8080/health

        {"status":"ok","info":{"chaos":{"status":"up"}},"error":{},"details":{"chaos":{"status":"up"}}}


Confirm traffic is routing through Envoy (look for server: envoy and x-envoy-upstream-service-time):


    $ curl -v -s http://catalog:8080/catalog/products 2>&1 | grep -iE "server:|x-envoy"

        < x-envoy-upstream-service-time: 2
        < server: envoy        


A quick health sweep across all four:

    $ for svc in catalog carts orders checkout; do
        echo "== $svc =="
        curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://$svc:8080/actuator/health"
    done


        == catalog ==
        HTTP 404
        == carts ==
        HTTP 200
        == orders ==
        HTTP 200
        == checkout ==
        HTTP 404

# Note: 

catalog (Go) and checkout (Node) use /health, while carts and orders (Java/Spring) use /actuator/health — so a 404 on /actuator/health for catalog/checkout is expected; try /health for those.

That 404 vs the earlier 000 is the whole story: names resolve via hosts to the 127.255.0.x local Envoy proxy, which only listens on your configured client-alias port (8080 here), and it forwards to healthy remote tasks.    