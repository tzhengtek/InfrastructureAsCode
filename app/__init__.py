from flask import Flask
from .common import app_config
from .models import db


def create_app():
    app = Flask(__name__)

    app.config['JWT_SECRET'] = app_config.get('JWT_SECRET')
    if not app_config["db_host"]:
        app.config['SQLALCHEMY_DATABASE_URI'] = (
            f"postgresql://{app_config['db_user']}:{app_config['db_pass']}@/"
            f"{app_config['db_name']}?host=/cloudsql/{app_config['db_conn_name']}"
        )
    else:
        # Standard Development connection string
        app.config['SQLALCHEMY_DATABASE_URI'] = f"postgresql://{app_config['db_user']}:{app_config['db_pass']}@{app_config['db_host']}:5432/{app_config['db_name']}"
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)
    with app.app_context():
        db.create_all()

    from .health_routes import bp as health_bp
    from .tasks_routes import bp as tasks_bp

    app.register_blueprint(health_bp)
    app.register_blueprint(tasks_bp)

    return app
