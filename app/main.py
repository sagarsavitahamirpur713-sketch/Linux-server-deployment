"""
main.py
--------
Simple Flask app to demonstrate a production-style deployment.
Replace this with your real application logic later — the deployment
pipeline (systemd + nginx + https) stays the same either way.
"""

from flask import Flask, jsonify
import socket
import datetime

app = Flask(__name__)


@app.route("/")
def home():
    return jsonify({
        "message": "Hello from your deployed Linux server!",
        "hostname": socket.gethostname(),
        "time_utc": datetime.datetime.utcnow().isoformat()
    })


@app.route("/health")
def health():
    """Used by monitoring tools / load balancers to check app status."""
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    # Only for local testing. In production, gunicorn runs this app
    # (see systemd/myapp.service) — never run app.run() on a real server.
    app.run(host="0.0.0.0", port=5000, debug=True)
