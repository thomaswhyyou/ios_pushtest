from apns import APNs, Payload
from flask import Flask, render_template, redirect, request

apns = APNs(use_sandbox=True,
            cert_file="pems/PushTestCert.pem",
            key_file="pems/PushTestKey.pem")

DEBUG = False
app = Flask(__name__)
app.config.from_object(__name__)

@app.route("/")
def index_get():
    return render_template("index.html")

@app.route("/", methods=["POST"])
def index_post():
    message = request.form.get("message")
    token_hex = "fef5ddd709797cb79acfaabf5d8cd22148d5c947cbacf24c6be251ce7dc27c7e"
    payload = Payload(alert=message, sound="default", badge=1)
    apns.gateway_server.send_notification(token_hex, payload)
    return redirect("/", code=302)

if __name__ == "__main__":
    app.config.update(
        DEBUG=True,
    )
    app.run("0.0.0.0")
