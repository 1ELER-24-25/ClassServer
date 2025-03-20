from flask import Flask, render_template, jsonify, session, request, redirect, url_for, flash
from flask_login import LoginManager, login_user, login_required, logout_user, current_user
import psycopg2
import os
import uuid
from models import User

app = Flask(__name__)
app.secret_key = os.environ.get('FLASK_SECRET_KEY')
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

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

@login_manager.user_loader
def load_user(user_id):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, username, rfid_uid, password_hash FROM users WHERE id = %s", (user_id,))
            user_data = cur.fetchone()
            if user_data:
                return User(
                    id=user_data[0],
                    username=user_data[1],
                    rfid=user_data[2],
                    password_hash=user_data[3]
                )
    return None

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        identifier = request.form['identifier']
        password = request.form['password']
        
        with get_db_connection() as conn:
            user = User.get_by_identifier(identifier, conn)
            
            if user and user.check_password(password):
                login_user(user)
                next_page = request.args.get('next')
                return redirect(next_page or url_for('home'))
            
            return render_template('login.html', error="Invalid credentials")
    
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('home'))

# Protected routes require @login_required
@app.route('/virtual-board')
@login_required
def virtual_board():
    board_id = f"WEB-{uuid.uuid4().hex[:8]}"
    return render_template('online_chess.html', 
                         board_id=board_id,
                         user_rfid=current_user.rfid)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
