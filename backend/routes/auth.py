from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import Optional
from ..database import get_db
from ..models import User
from ..schemas import UserResponse, RFIDAuthResponse
from ..utils.name_generator import generate_username, generate_temp_password
from ..utils.auth import get_password_hash, create_access_token
from sqlalchemy.exc import SQLAlchemyError
import logging

router = APIRouter()

logger = logging.getLogger(__name__)

@router.post("/rfid/auth", response_model=RFIDAuthResponse)
async def rfid_auth(rfid_uid: str, db: Session = Depends(get_db)):
    """
    Authenticate or create a user with RFID card.
    If the card is not registered, creates a new user with temporary credentials.
    """
    # Validate RFID format
    if not is_valid_rfid_format(rfid_uid):
        raise HTTPException(status_code=400, detail="Invalid RFID format")
    
    # Check if the RFID card is already registered
    user = db.query(User).filter(User.rfid_uid == rfid_uid).first()
    
    if user:
        # Card is registered, return user info
        token = create_access_token(data={"sub": user.email})
        return {
            "is_new_user": False,
            "user": UserResponse.from_orm(user),
            "access_token": token,
            "token_type": "bearer"
        }
    
    # Card is not registered, create a new user
    temp_username = generate_username()
    temp_password = generate_temp_password()
    hashed_password = get_password_hash(temp_password)
    
    new_user = User(
        username=temp_username,
        email=f"{temp_username.lower()}@temporary.com",
        rfid_uid=rfid_uid,
        hashed_password=hashed_password,
        is_temporary=True,  # Flag to indicate this is a temporary account
        isAdmin=False,
        active=True
    )
    
    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        token = create_access_token(data={"sub": new_user.email})
        return {
            "is_new_user": True,
            "user": UserResponse.from_orm(new_user),
            "access_token": token,
            "token_type": "bearer",
            "temp_password": temp_password  # Include temporary password in response
        }
    except SQLAlchemyError as e:
        db.rollback()
        logger.error(f"Database error: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error")
    except Exception as e:
        db.rollback()
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error") 