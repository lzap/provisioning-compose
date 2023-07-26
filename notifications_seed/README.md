# Notifications setup

[Notifications](https://github.com/RedHatInsights/notifications-backend) service handles notifications across services and allows email templates, webhook and 3rd party apps integration.
Users can subscribed to an event type. There are two event types related to image launch, a launch success and a launch failure.
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

## Message content
Messages are sent to notifications service via kafka.
The `context` object contains the launch ID and the provider.
The `Events` object contains the deployed instances detail, such as IP and DNS or an error when the launch fails.

For example, a successful launch event looks like:
```json
{
  "account_id": "123456",
  "application": "image-builder",
  "bundle": "rhel",
  "context": {
    "launch_id": 3011,
    "provider": "aws"
  },
  "event_type": "launch-success",
  "events": [
    {
      "payload": {
        "instance_id": "ie-12231",
        "detail": {
          "public_dns": "34.111.195.19.example.com",
          "public_ipv4": "34.111.195.19"
        }
      },
      "metadata": {}
    }
  ],
  "org_id": "123456",
  "timestamp": "2023-07-17T08:23:46.892",
}
```

## Email templates
All templates are written in [Qute templating engine](https://quarkus.io/guides/qute-reference).
Ours app templates can be found in `notifications/engine/src/main/resources/templates/ImageBuilder` dir.
There are two kind of emails, an instant email, which triggers after an event (i.e successful launch) occurs, and a daily aggregated email, which summarizes all the daily launch attempts.

### File structure
```
   ├── templates
   │   ├── ImageBuilder
   │   │   ├── dailyEmailBodyV2.html
   │   │   ├── dailyEmailTitleV2.txt
   │   │   ├── launchSuccessInstantEmailBodyV2.html
   │   │   ├── launchSuccessInstantEmailTitleV2.txt
   │   │   ├── launchFailedInstantEmailBodyV2.html
   │   │   ├── launchFailedInstantEmailTitleV2.txt
   └── 
```

### Editing a template
The message's context and events are accessible in a template.
For example, to get the launch's provider:
```
{action.context.provider}
```
To iterate over a launch deployed instances
```
   {#each action.events}
      {it.payload.instance_id}
      {it.payload.detail.public_ipv4}
      {it.payload.detail.public_dns}
   {/each}
```

### Daily email
A daily email is generated every 24 hours, it is defined by an aggregator, which can be find in `aggregators/ImageBuilderAggregator.java`, it creates the following json object:

```json
"aws": {"instances": 12, "launch_success": 2, "failures": 0},
"gcp": {"instances": 0, "launch_success": 0, "failures": 1}.
"azure": {"instances": 10, "launch_success": 1, "failures": 0},
"errors": ["some error"],
"launch_success": 3
```

The aggregation payload is accessible in the daily template,
For example, to get all aws deployed instances amount:
```
{action.context.images.aws.instances}
```

### Testing
There are tests for email templates,
you can find related test in `engine/src/test/java/com/redhat/cloud/notifications/templates/TestImageBuilderTemplate.java`
In order to run these tests, run:

```sh
# notifications/engine dir
mvn test -Dtest="TestImageBuilderTemplate" -Dmockserver.logLevel=INFO 
```
