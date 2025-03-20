import os

class Config:
    FLASK_SECRET_KEY = os.environ.get('FLASK_SECRET_KEY')
    POSTGRES_HOST = "postgres"
    POSTGRES_DB = os.environ.get('POSTGRES_DB')
    POSTGRES_USER = os.environ.get('POSTGRES_USER')
    POSTGRES_PASSWORD = os.environ.get('POSTGRES_PASSWORD')

class DevelopmentConfig(Config):
    DEBUG = True

class ProductionConfig(Config):
    DEBUG = False

class TestingConfig(Config):
    TESTING = True
    # Use test database
    POSTGRES_DB = "test_db"