from flask import Flask, render_template, jsonify
from flask_login import LoginManager, login_required
import psycopg2
import os

app = Flask(__name__)
app.secret_key = os.environ.get('FLASK_SECRET_KEY')
login_manager = LoginManager()
login_manager.init_app(app)

# Database connection
def get_db_connection():
    return psycopg2.connect(
        host="postgres",
        database=os.environ.get('POSTGRES_DB'),
        user=os.environ.get('POSTGRES_USER'),
        password=os.environ.get('POSTGRES_PASSWORD')
    )

# API routes for dynamic content
@app.route('/api/active-games')
def get_active_games():
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM games WHERE status = 'active'")
            games = cur.fetchall()
    return jsonify(games)

@app.route('/api/leaderboard')
def get_leaderboard():
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT u.username, er.rating, er.game_type 
                FROM elo_ratings er 
                JOIN users u ON er.user_id = u.id 
                ORDER BY er.rating DESC
            """)
            rankings = cur.fetchall()
    return jsonify(rankings)

# Page routes
@app.route('/')
def home():
    return render_template('home.html')

@app.route('/server-info')
def server_info():
    info = {
        'mqtt': {'host': 'localhost', 'port': 1883},
        'nodered': {'url': 'http://localhost:1880'},
        'influxdb': {'url': 'http://localhost:8086'},
        'adminer': {'url': 'http://localhost:8080'}
    }
    return render_template('server_info.html', info=info)

@app.route('/mqtt-docs')
def mqtt_docs():
    return render_template('mqtt_docs.html')

@app.route('/profile')
@login_required
def profile():
    return render_template('profile.html')

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
