from flask import Flask, render_template, jsonify, session, request, redirect, url_for, flash
from flask_login import LoginManager, login_user, login_required, logout_user, current_user
import psycopg2
import os
import uuid
import socket
from models import User

app = Flask(__name__)
app.secret_key = os.environ.get('FLASK_SECRET_KEY')
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# Database connection
def get_db_connection():
    try:
        db_params = {
            'host': "postgres",
            'database': os.environ.get('POSTGRES_DB'),
            'user': os.environ.get('POSTGRES_USER'),
            'password': os.environ.get('POSTGRES_PASSWORD')
        }
        
        # Debug print
        print("Database connection parameters:")
        for key, value in db_params.items():
            print(f"{key}: {'[SET]' if value else '[NOT SET]'}")
            
        return psycopg2.connect(**db_params)
    except Exception as e:
        print(f"Database connection error: {e}")
        print(f"Environment variables:")
        print(f"POSTGRES_DB: {os.environ.get('POSTGRES_DB')}")
        print(f"POSTGRES_USER: {os.environ.get('POSTGRES_USER')}")
        print(f"POSTGRES_PASSWORD length: {len(os.environ.get('POSTGRES_PASSWORD', '')) if os.environ.get('POSTGRES_PASSWORD') else 'NOT SET'}")
        raise

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
    # Change the default fallback value to match .env
    ip_address = os.environ.get('SERVER_IP', '192.168.1.216')
    
    info = {
        'mqtt': {'host': ip_address, 'port': 1883},
        'nodered': {'url': f'http://{ip_address}:1880'},
        'influxdb': {'url': f'http://{ip_address}:8086'},
        'adminer': {'url': f'http://{ip_address}:8080'},
        'grafana': {'url': f'http://{ip_address}:3000'}
    }
    return render_template('server_info.html', info=info)

@app.route('/mqtt-docs')
def mqtt_docs():
    ip_address = os.environ.get('SERVER_IP', '192.168.1.216')
    info = {
        'mqtt': {'host': ip_address, 'port': 1883}
    }
    return render_template('mqtt_docs.html', info=info)

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

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        confirm_password = request.form['confirm_password']
        
        if password != confirm_password:
            return render_template('register.html', error="Passwords do not match")
        
        with get_db_connection() as conn:
            # Check if username exists
            with conn.cursor() as cur:
                cur.execute("SELECT 1 FROM users WHERE username = %s", (username,))
                if cur.fetchone():
                    return render_template('register.html', error="Username already exists")
            
            # Create new user
            try:
                user = User.create_web_user(username, password, conn)
                login_user(user)
                return redirect(url_for('home'))
            except Exception as e:
                return render_template('register.html', error="Registration failed")
    
    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        identifier = request.form['identifier']
        password = request.form['password']
        
        with get_db_connection() as conn:
            user = User.get_by_identifier(identifier, conn)
            
            # If RFID user doesn't exist, create new user
            if not user and identifier.startswith('RFID-'):
                user = User.create_rfid_user(identifier, conn)
                login_user(user)
                flash(f'New account created! Your username is: {user.username} and password is: 1234')
                return redirect(url_for('home'))
            
            # Normal login check
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
