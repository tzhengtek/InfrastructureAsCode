#!/usr/bin/env python3
"""
Script pour générer un token JWT pour tester l'API Task Manager
"""
import jwt
import argparse
from datetime import datetime, timedelta, timezone

def generate_token(secret, expires_in_hours=24):
    """Génère un token JWT valide"""
    now_utc = datetime.now(timezone.utc)
    payload = {
        'sub': 'test-user',
        'iat': now_utc,
        'exp': now_utc + timedelta(hours=expires_in_hours)
    }
    token = jwt.encode(payload, secret, algorithm='HS512')
    return token

def main():
    parser = argparse.ArgumentParser(description='Génère un token JWT pour l\'API Task Manager')
    parser.add_argument('--secret', required=True, help='Secret JWT')
    parser.add_argument('--expires', type=int, default=24, help='Heures avant expiration (défaut: 24)')
    args = parser.parse_args()
    token = generate_token(args.secret, args.expires)
    print(token)

if __name__ == '__main__':
    main()

