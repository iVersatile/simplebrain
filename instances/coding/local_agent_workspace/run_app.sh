#!/bin/bash
# This script runs the Flask application.
export FLASK_APP=app.py
flask run --host=0.0.0.0 --port=5000
