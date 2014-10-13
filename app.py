import os
from apns import APNs, Payload
from flask import Flask, render_template, request

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
apns = APNs(use_sandbox=True,
            cert_file=os.path.join(BASE_DIR, "pems", "PushTestCert.pem"),
            key_file=os.path.join(BASE_DIR, "pems", "PushTestKey.pem"))

DEBUG = False
app = Flask(__name__)
app.config.from_object(__name__)

@app.route("/", methods=["GET", "POST"])
def index_get():
    if request.method == "POST":
        message = request.form.get("message")
        token_hex = "fef5ddd709797cb79acfaabf5d8cd22148d5c947cbacf24c6be251ce7dc27c7e"
        payload = Payload(alert=message, sound="default", badge=1)
        apns.gateway_server.send_notification(token_hex, payload)

    return render_template("index.html")

if __name__ == "__main__":
    app.config.update(
        DEBUG=True,
    )
    app.run("0.0.0.0")
