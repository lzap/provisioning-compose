import os
import helpers

PORT = os.getenv('quarkus.http.port')
x_rh_id = os.getenv('X_RH_IDENTITY')
webhook_url = os.getenv("WEBHOOK_URL")

base_url = "http://notifications-backend:" + PORT

helpers.set_path_prefix(base_url)

bundle_name = "rhel"
bundle_description = "Red Hat Enterprise Linux"
app_name = "image-builder"
app_display_name = "Images"
event_type = "launch-success"
event_type_display_name = "Triggers an notification when a launch is successful"
bg_name = "behavior-group-webhook"


print(">>> create bundle")
bundle_id = helpers.add_bundle(bundle_name, bundle_description)

print(">>> create application")
app_id = helpers.add_application(bundle_id, app_name, app_display_name)

print(">>> add eventType to application")
et_id = helpers.add_event_type(app_id, event_type, event_type_display_name)

print(">>> create a behavior group")
bg_id = helpers.create_behavior_group(bg_name, bundle_id, x_rh_id )

print(">>> add event type to behavior group")
helpers.add_event_type_to_behavior_group(et_id["id"], bg_id, x_rh_id)

print(">>> create endpoint")
props = {
   "url": webhook_url,
   "method": "POST",
   "secret_token": "",
   "type": "webhook"
}
ep_id = helpers.create_endpoint("webhook-endpoint", x_rh_id, props)

print(">>> link endpoint to behaviour group ")
helpers.link_bg_endpoint(bg_id, ep_id, x_rh_id)
