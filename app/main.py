"""
main.py
-------
Simple Flask application for a production-style Linux deployment.

Deployment flow:
Browser → Nginx → Gunicorn → Flask
"""

from flask import Flask, jsonify
import socket
from datetime import datetime, timezone
import os

app = Flask(__name__)

APP_NAME = os.getenv("APP_NAME", "Linux Server Deployment")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")


@app.route("/")
def home():
    """Main application endpoint."""
    return jsonify({
        "message": "Hello from your deployed Linux server!",
        "application": APP_NAME,
        "version": APP_VERSION,
        "hostname": socket.gethostname(),
        "time_utc": datetime.now(timezone.utc).isoformat()
    })


@app.route("/health")
def health():
    """Health check endpoint for monitoring systems."""
    return jsonify({
        "status": "ok",
        "application": APP_NAME
    }), 200


@app.route("/api/info")
def info():
    """Return basic application information."""
    return jsonify({
        "application": APP_NAME,
        "version": APP_VERSION,
        "hostname": socket.gethostname()
    }), 200


if __name__ == "__main__":
    # Local development only.
    # Production uses Gunicorn.
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=False
    )
