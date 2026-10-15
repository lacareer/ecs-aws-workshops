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

Follow this command to see images after deployment as the WS is missing some steps it appears

    # 1. Confirm you're in the right directory
    $ cd /srv/assets
    
    $ pwd
    
    $ ls -al [shoould be empty at this point]

    # 2. Install tools and pull the sample images into the EFS mount
    $ dnf -y install wget unzip
    
    wget -O /tmp/archive.zip \
    https://github.com/aws-containers/retail-store-sample-app/releases/download/v1.2.3/sample-images.zip \
    && unzip /tmp/archive.zip -d /srv/assets

    #re-verify
    $ ls -al *.jpg [shoould not empty at this point]
    
    $ dnf -y install ImageMagick
    
    $ mogrify -colorspace Gray *.jpg

