from . import create_app

if __name__ == '__main__':
    app = create_app()
    host = app.config.get('HOST', '0.0.0.0')
    port = int(app.config.get('PORT', 8080))
    cert_path = app.config.get('SSL_CERT_PATH', 'cert.pem')
    key_path = app.config.get('SSL_KEY_PATH', 'key.pem')

    import os
    if os.path.exists(cert_path) and os.path.exists(key_path):
        app.run(host=host, port=port, ssl_context=(cert_path, key_path), debug=False)
    else:
        app.run(host=host, port=port, debug=False
)
