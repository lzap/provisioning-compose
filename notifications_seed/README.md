# Notifications setup

[Notifications](https://github.com/RedHatInsights/notifications-backend) service handles notifications across services and allows email templates, webhook and 3rd party apps integration.

## Setup

1. Copy [notifications-backend.example.env](/notifications-backend.example.env) to `notifications-backend.env`, it contains the required variables for notifications service, just add `WEBHOOK_URL` (you can use https://webhook.site) and `X_RH_IDENTITY`. Notice that the `x_rh_id` needs to contain a user object, for example:
   ```json
   "identity":{"type":"User","account_number":"","org_id":"","user":{"username":"","email":"","first_name":"","last_name":""}}
   ```
2. To seed the data, run once
```sh
$ COMPOSE_PROFILES= docker compose --profile kafka,notifications,notifications-init up 
```
Alternatively, with podman:
```sh
pip3 install podman-compose
$ podman-compose --profile kafka --profile notifications --profile notifications-init up
```
The `notifications-init` profile seeds the required provisioning data, required for the first use.
