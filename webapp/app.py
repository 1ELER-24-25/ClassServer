from flask import Flask, render_template, jsonify, session, request, redirect, url_for, flash
from flask_login import LoginManager, login_user, login_required, logout_user, current_user
import psycopg2
import psycopg2.extras # For dictionary cursor
import os
import uuid
import socket
import json # For handling JSONB
from datetime import datetime # For timestamps
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
        conn = psycopg2.connect(**db_params)
        # Use dictionary cursor for easier access to columns by name
        conn.cursor_factory = psycopg2.extras.DictCursor
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        print(f"Environment variables:")
        print(f"POSTGRES_DB: {os.environ.get('POSTGRES_DB')}")
        print(f"POSTGRES_USER: {os.environ.get('POSTGRES_USER')}")
        print(f"POSTGRES_PASSWORD length: {len(os.environ.get('POSTGRES_PASSWORD', '')) if os.environ.get('POSTGRES_PASSWORD') else 'NOT SET'}")
        raise

# --- Helper Functions for Courses ---

def get_or_create_user_course_progress(user_id, course_id, conn):
    """Gets or creates a user's progress record for a specific course."""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT * FROM user_course_progress WHERE user_id = %s AND course_id = %s",
            (user_id, course_id)
        )
        progress = cur.fetchone()
        if not progress:
            cur.execute(
                """INSERT INTO user_course_progress (user_id, course_id, status) 
                   VALUES (%s, %s, 'in_progress') RETURNING *""",
                (user_id, course_id)
            )
            progress = cur.fetchone()
            conn.commit()
        return progress

def get_or_create_user_module_progress(user_course_progress_id, module_id, conn):
    """Gets or creates a user's progress record for a specific module."""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT * FROM user_module_progress WHERE user_course_progress_id = %s AND module_id = %s",
            (user_course_progress_id, module_id)
        )
        module_progress = cur.fetchone()
        if not module_progress:
            cur.execute(
                """INSERT INTO user_module_progress (user_course_progress_id, module_id, status) 
                   VALUES (%s, %s, 'in_progress') RETURNING *""",
                (user_course_progress_id, module_id)
            )
            module_progress = cur.fetchone()
            conn.commit()
        return module_progress

def calculate_score(user_course_progress_id, conn):
    """Calculates the final score based on hints used, with different penalties."""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT hints_used_mask FROM user_module_progress WHERE user_course_progress_id = %s",
            (user_course_progress_id,)
        )
        masks = cur.fetchall()
        
        total_penalty = 0
        for row in masks:
            mask = row['hints_used_mask']
            # Check each hint bit
            if mask & 8:  # Hint 4 (Sniktitt) used (Bit 3, value 8)
                total_penalty += 10
            if mask & 1:  # Hint 1 used (Bit 0, value 1)
                total_penalty += 5
            if mask & 2:  # Hint 2 used (Bit 1, value 2)
                total_penalty += 5
            if mask & 4:  # Hint 3 used (Bit 2, value 4)
                total_penalty += 5
                
        score = max(0, 100 - total_penalty)
        return score

# --- API routes ---
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
    completed_courses = []
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT c.id, c.title, ucp.score, ucp.completed_at 
                FROM user_course_progress ucp
                JOIN courses c ON ucp.course_id = c.id
                WHERE ucp.user_id = %s AND ucp.status = 'completed'
                ORDER BY ucp.completed_at DESC
            """, (current_user.id,))
            completed_courses = cur.fetchall()
            
    # Pass user info and completed courses to template
    return render_template('profile.html', user=current_user, completed_courses=completed_courses)


# --- Programming Course Routes ---

@app.route('/courses')
@login_required
def list_courses():
    """Displays a list of available programming courses."""
    courses = []
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, title, description, language FROM courses ORDER BY id")
            courses = cur.fetchall()
    return render_template('courses_list.html', courses=courses)

@app.route('/courses/<int:course_id>')
@login_required
def course_detail(course_id):
    """Displays details for a specific course and its modules."""
    course = None
    modules = []
    user_progress = None
    module_statuses = {} # Store module status for the user

    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # Get course details
            cur.execute("SELECT * FROM courses WHERE id = %s", (course_id,))
            course = cur.fetchone()
            if not course:
                flash("Kurs ikke funnet.", "error")
                return redirect(url_for('list_courses'))

            # Get modules for the course
            cur.execute("SELECT * FROM modules WHERE course_id = %s ORDER BY order_num", (course_id,))
            modules = cur.fetchall()

            # Get user's progress for this course (if any)
            cur.execute("SELECT * FROM user_course_progress WHERE user_id = %s AND course_id = %s", (current_user.id, course_id))
            user_progress = cur.fetchone()

            # Get statuses for each module if progress exists
            if user_progress:
                cur.execute("""
                    SELECT module_id, status 
                    FROM user_module_progress 
                    WHERE user_course_progress_id = %s
                """, (user_progress['id'],))
                statuses = cur.fetchall()
                module_statuses = {row['module_id']: row['status'] for row in statuses}

    return render_template('course_detail.html', 
                           course=course, 
                           modules=modules, 
                           user_progress=user_progress,
                           module_statuses=module_statuses)


@app.route('/courses/<int:course_id>/modules/<int:module_id>')
@login_required
def module_detail(course_id, module_id):
    """Displays a single module's content and handles progress."""
    module = None
    course = None
    user_course_prog = None
    user_module_prog = None
    available_hints = []
    next_module_id = None # Variable for next module ID

    with get_db_connection() as conn:
        # Get module details and ensure it belongs to the course
        with conn.cursor() as cur:
            cur.execute("""
                SELECT m.*, c.language 
                FROM modules m
                JOIN courses c ON m.course_id = c.id
                WHERE m.id = %s AND m.course_id = %s
            """, (module_id, course_id))
            module = cur.fetchone()
            if not module:
                flash("Modul ikke funnet.", "error")
                return redirect(url_for('course_detail', course_id=course_id))
            
            # Get or create user progress records
            user_course_prog = get_or_create_user_course_progress(current_user.id, course_id, conn)
            user_module_prog = get_or_create_user_module_progress(user_course_prog['id'], module_id, conn)

            # Get available hint numbers for this module
            cur.execute("SELECT hint_number FROM hints WHERE module_id = %s ORDER BY hint_number", (module_id,))
            hints_data = cur.fetchall()
            available_hints = [row['hint_number'] for row in hints_data]

            # Find the next module ID if this one isn't the last
            cur.execute("""
                 SELECT id 
                 FROM modules 
                 WHERE course_id = %s AND order_num > %s
                 ORDER BY order_num ASC 
                 LIMIT 1
             """, (course_id, module['order_num']))
            next_module_data = cur.fetchone()
            if next_module_data:
                next_module_id = next_module_data['id']

    # Safely parse documentation links
    doc_links = []
    if module and module['documentation_links']:
        try:
            doc_links = json.loads(module['documentation_links']) if isinstance(module['documentation_links'], str) else module['documentation_links']
        except json.JSONDecodeError:
            print(f"Warning: Could not parse documentation_links JSON for module {module_id}")
            doc_links = [] # Default to empty list on error

    return render_template('module_detail.html', 
                           module=module,
                           course_id=course_id,
                           user_module_progress=user_module_prog,
                           doc_links=doc_links,
                           available_hints=available_hints,
                           next_module_id=next_module_id) # Pass next module ID


@app.route('/api/courses/<int:course_id>/modules/<int:module_id>/hint/<int:hint_number>', methods=['POST'])
@login_required
def get_hint(course_id, module_id, hint_number):
    """API endpoint to retrieve a hint and record its usage."""
    hint = None
    user_course_prog = None
    user_module_prog = None

    # Allow hint number 4 for the API endpoint
    if hint_number not in [1, 2, 3, 4]:
        return jsonify({"error": "Ugyldig hint nummer."}), 400

    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # Verify module exists
            cur.execute("SELECT 1 FROM modules WHERE id = %s AND course_id = %s", (module_id, course_id))
            if not cur.fetchone():
                return jsonify({"error": "Modul ikke funnet."}), 404

            # Get hint text
            cur.execute("SELECT hint_text FROM hints WHERE module_id = %s AND hint_number = %s", (module_id, hint_number))
            hint = cur.fetchone()
            if not hint:
                return jsonify({"error": "Hint ikke funnet."}), 404

            # Get/create progress records
            user_course_prog = get_or_create_user_course_progress(current_user.id, course_id, conn)
            user_module_prog = get_or_create_user_module_progress(user_course_prog['id'], module_id, conn)

            # Update hints_used_mask using bitwise OR
            hint_bit = 1 << (hint_number - 1) # 1 for hint 1, 2 for hint 2, 4 for hint 3
            if not (user_module_prog['hints_used_mask'] & hint_bit):
                new_mask = user_module_prog['hints_used_mask'] | hint_bit
                cur.execute(
                    "UPDATE user_module_progress SET hints_used_mask = %s WHERE id = %s",
                    (new_mask, user_module_prog['id'])
                )
                conn.commit()

    return jsonify({"hint_text": hint['hint_text']})


@app.route('/courses/<int:course_id>/modules/<int:module_id>/complete', methods=['POST'])
@login_required
def complete_module(course_id, module_id):
    """Marks a module as completed and checks for course completion."""
    user_course_prog = None
    user_module_prog = None
    total_modules_in_course = 0
    completed_modules_count = 0

    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # Get/create progress records
            user_course_prog = get_or_create_user_course_progress(current_user.id, course_id, conn)
            user_module_prog = get_or_create_user_module_progress(user_course_prog['id'], module_id, conn)

            # Mark module as completed if not already
            if user_module_prog['status'] != 'completed':
                cur.execute(
                    "UPDATE user_module_progress SET status = 'completed', completed_at = %s WHERE id = %s",
                    (datetime.utcnow(), user_module_prog['id'])
                )
                conn.commit()
                # Refresh status after update
                user_module_prog = get_or_create_user_module_progress(user_course_prog['id'], module_id, conn)


            # Check if the course is now complete
            # 1. Count total modules in the course
            cur.execute("SELECT COUNT(*) FROM modules WHERE course_id = %s", (course_id,))
            total_modules_in_course = cur.fetchone()['count']

            # 2. Count completed modules for the user in this course
            cur.execute("""
                SELECT COUNT(*) 
                FROM user_module_progress 
                WHERE user_course_progress_id = %s AND status = 'completed'
            """, (user_course_prog['id'],))
            completed_modules_count = cur.fetchone()['count']

            # 3. If all modules completed, update course progress and calculate score
            if completed_modules_count >= total_modules_in_course and user_course_prog['status'] != 'completed':
                final_score = calculate_score(user_course_prog['id'], conn)
                cur.execute("""
                    UPDATE user_course_progress 
                    SET status = 'completed', score = %s, completed_at = %s 
                    WHERE id = %s
                """, (final_score, datetime.utcnow(), user_course_prog['id']))
                conn.commit()
                flash("Gratulerer! Du har fullført kurset!", "success")
                # Redirect to diploma page upon course completion
                return redirect(url_for('diploma', course_id=course_id))

    # Find the next module in the course
    next_module = None
    with get_db_connection() as conn:
        with conn.cursor() as cur:
             cur.execute("""
                 SELECT id 
                 FROM modules 
                 WHERE course_id = %s AND order_num > (SELECT order_num FROM modules WHERE id = %s)
                 ORDER BY order_num ASC 
                 LIMIT 1
             """, (course_id, module_id))
             next_module = cur.fetchone()

    if next_module:
        return redirect(url_for('module_detail', course_id=course_id, module_id=next_module['id']))
    else:
        # Should have been caught by completion check, but redirect to course page as fallback
        return redirect(url_for('course_detail', course_id=course_id))


@app.route('/courses/<int:course_id>/diploma')
@login_required
def diploma(course_id):
    """Displays the diploma/certificate for a completed course."""
    diploma_data = None
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT u.username, c.title AS course_title, ucp.score, ucp.completed_at
                FROM user_course_progress ucp
                JOIN users u ON ucp.user_id = u.id
                JOIN courses c ON ucp.course_id = c.id
                WHERE ucp.user_id = %s AND ucp.course_id = %s AND ucp.status = 'completed'
            """, (current_user.id, course_id))
            diploma_data = cur.fetchone()

    if not diploma_data:
        flash("Diplom ikke funnet eller kurset er ikke fullført.", "error")
        return redirect(url_for('course_detail', course_id=course_id))

    # Pass both diploma_data and course_id to the template
    return render_template('diploma.html', diploma=diploma_data, course_id=course_id)


# --- User Authentication and Management ---

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
    # Ensure the host is 0.0.0.0 to be accessible within Docker network
    app.run(host='0.0.0.0', port=5000, debug=os.environ.get('FLASK_DEBUG', 'False') == 'True')
