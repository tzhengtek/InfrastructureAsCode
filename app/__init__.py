import os
from flask import Flask
from .common import app_config


def create_app():
    app = Flask(__name__)

    app.config['JWT_SECRET'] = app_config.get('JWT_SECRET')
    app_config['JWT_SECRET'] = app.config['JWT_SECRET']

    from .health_routes import bp as health_bp
    from .tasks_routes import bp as tasks_bp

    app.register_blueprint(health_bp)
    app.register_blueprint(tasks_bp)

    return app
