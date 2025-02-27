from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes import auth  # Import routers

app = FastAPI(title="ClassServer API")

# Configure CORS - restrict in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace with specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="")  # No prefix since Nginx handles it

@app.get("/")
async def root():
    return {"message": "Welcome to ClassServer API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"} 