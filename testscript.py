# import time
from apns import APNs, Payload

apns = APNs(use_sandbox=True, cert_file='PushTestCert.pem', key_file='PushTestKey.pem')

# Send a notification
token_hex = "fef5ddd709797cb79acfaabf5d8cd22148d5c947cbacf24c6be251ce7dc27c7e"
payload = Payload(alert="Yolo!", sound="default", badge=1)
apns.gateway_server.send_notification(token_hex, payload)
