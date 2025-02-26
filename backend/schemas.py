from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    username: str
    email: EmailStr
    isAdmin: bool = False
    active: bool = True
    rfid_uid: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = None
    rfid_uid: Optional[str] = None

class UserResponse(UserBase):
    id: int
    created_at: datetime
    is_temporary: bool = False

    class Config:
        orm_mode = True

class RFIDAuthResponse(BaseModel):
    is_new_user: bool
    user: UserResponse
    access_token: str
    token_type: str
    temp_password: Optional[str] = None  # Only included for new users 