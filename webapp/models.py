from flask_login import UserMixin
from werkzeug.security import check_password_hash, generate_password_hash
from utils.name_generator import generate_username, generate_dummy_rfid

class User(UserMixin):
    def __init__(self, id, username, rfid, password_hash):
        self.id = id
        self.username = username
        self.rfid = rfid
        self.password_hash = password_hash

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    @staticmethod
    def get_by_identifier(identifier, db_connection):
        """Get user by either RFID or username"""
        with db_connection.cursor() as cur:
            cur.execute("""
                SELECT id, username, rfid_uid, password_hash 
                FROM users 
                WHERE username = %s OR rfid_uid = %s
            """, (identifier, identifier))
            user_data = cur.fetchone()
            
            if user_data:
                return User(
                    id=user_data[0],
                    username=user_data[1],
                    rfid=user_data[2],
                    password_hash=user_data[3]
                )
        return None

    @staticmethod
    def create_web_user(username, password, db_connection):
        """Create a new user through web registration"""
        dummy_rfid = generate_dummy_rfid()
        password_hash = generate_password_hash(password)
        
        with db_connection.cursor() as cur:
            cur.execute("""
                INSERT INTO users (username, rfid_uid, password_hash)
                VALUES (%s, %s, %s)
                RETURNING id
            """, (username, dummy_rfid, password_hash))
            user_id = cur.fetchone()[0]
            db_connection.commit()
            
            return User(
                id=user_id,
                username=username,
                rfid=dummy_rfid,
                password_hash=password_hash
            )

    @staticmethod
    def create_rfid_user(rfid, db_connection, default_password="1234"):
        """Create a new user from RFID scan"""
        username = generate_username()
        # Keep generating until we find a unique username
        while True:
            with db_connection.cursor() as cur:
                cur.execute("SELECT 1 FROM users WHERE username = %s", (username,))
                if not cur.fetchone():
                    break
                username = generate_username()
        
        password_hash = generate_password_hash(default_password)
        
        with db_connection.cursor() as cur:
            cur.execute("""
                INSERT INTO users (username, rfid_uid, password_hash)
                VALUES (%s, %s, %s)
                RETURNING id
            """, (username, rfid, password_hash))
            user_id = cur.fetchone()[0]
            db_connection.commit()
            
            return User(
                id=user_id,
                username=username,
                rfid=rfid,
                password_hash=password_hash
            )
