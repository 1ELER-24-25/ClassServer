from flask_login import UserMixin
from werkzeug.security import check_password_hash

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