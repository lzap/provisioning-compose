#!/bin/bash
BASEDIR=$(dirname $0)
source $BASEDIR/../sources.env
[[ -f $BASEDIR/sources.conf ]] && source $BASEDIR/sources.conf

IDENTITY=$($BASEDIR/identity_header.sh $ACCOUNT_ID $ORG_ID)
echo "Identity: $IDENTITY"

curl --location -g --request POST "http://localhost:$PORT/api/sources/v3.1/bulk_create" \
--header "$IDENTITY" \
-d "$(cat <<EOF
{
  "sources": [
    {
      "name": "Amazon source",
      "source_type_name": "amazon",
      "app_creation_workflow": "manual_configuration"
    }
  ],
  "applications": [
    {
      "source_name": "Amazon source",
      "application_type_name": "provisioning"
    }
  ],
  "authentications": [
    {
      "resource_type": "Application",
      "resource_name": "provisioning",
      "username": "$ARN_ROLE",
      "authtype":"provisioning-arn"
    }
  ]
}
EOF
)"

curl --location -g --request POST "http://localhost:$PORT/api/sources/v3.1/bulk_create" \
--header "$IDENTITY" \
-d "$(cat <<EOF
{
  "sources": [
    {
      "name": "Azure source",
      "source_type_name": "azure",
      "app_creation_workflow": "manual_configuration"
    }
  ],
  "applications": [
    {
      "source_name": "Azure source",
      "application_type_name": "provisioning"
    }
  ],
  "authentications": [
    {
      "resource_type": "Application",
      "resource_name": "provisioning",
      "username": "$SUBSCRIPTION_ID",
      "authtype":"provisioning_lighthouse_subscription_id"
    }
  ]
}
EOF
)"

curl --location -g --request POST "http://localhost:$PORT/api/sources/v3.1/bulk_create" \
--header "$IDENTITY" \
-d "$(cat <<EOF
{
  "sources": [
    {
      "name": "Google source",
      "source_type_name": "google",
      "app_creation_workflow": "manual_configuration"
    }
  ],
  "applications": [
    {
      "source_name": "Google source",
      "application_type_name": "provisioning"
    }
  ],
  "authentications": [
    {
      "resource_type": "Application",
      "resource_name": "provisioning",
      "username": "$PROJECT_ID",
      "authtype":"provisioning_project_id"
    }
  ]
}
EOF
)"
