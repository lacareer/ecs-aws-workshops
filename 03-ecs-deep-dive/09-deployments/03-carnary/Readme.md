Thios is very similar to Blue/Green setup

Just that the Deploymeent Configuration chnages from BLUE_GREEN to CANARY

All theother stuff are just same or similar


<!-- How the canary runs under CloudFormation -->
- Initial create-stack launches the service on the blue target group (prod rule = 100% blue / 0% green). No traffic shift happens on first create.

- To trigger the canary, change something in the task definition (e.g., set UiTheme=orange) and update-stack. 
  ECS registers the green revision, shifts the test listener (8080) to green, then moves CanaryPercent (25%) of port-80 traffic to green, holds for CanaryBakeTimeInMinutes (60), shifts the remaining 75%, waits BakeTimeInMinutes (2), and terminates blue.

- The workshop's lifecycleHooks: [] maps to simply not defining LifecycleHooks here — canary progresses automatically with no approval gate.

<!-- Hands-On Rollback Exercise -->
- Click on the UI service
- Click on Deployment
- Click the Rollback button in the top-right corner and confirm.

# What Happens During Rollback
When you confirm the rollback:

- ECS immediately halts the traffic shift
- Production traffic reverts to 100% blue
- The green tasks are terminated
- The deployment status shows "Rollback succeeded"
- The rollback completes within 1-2 minutes.