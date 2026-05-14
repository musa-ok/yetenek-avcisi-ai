import pytest
import tempfile
import os
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from backend.main import app
from backend.database import Base, get_db

# Test database setup
@pytest.fixture(scope="session")
def test_db():
    """Create test database for the test session"""
    # Create temporary database file
    db_fd, db_path = tempfile.mkstemp()
    database_url = f"sqlite:///{db_path}"
    
    engine = create_engine(database_url, connect_args={"check_same_thread": False})
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    Base.metadata.create_all(bind=engine)
    
    yield TestingSessionLocal
    
    # Cleanup
    os.close(db_fd)
    os.unlink(db_path)

@pytest.fixture(scope="function")
def db_session(test_db):
    """Create a fresh database session for each test"""
    session = test_db()
    try:
        yield session
    finally:
        session.rollback()
        session.close()

@pytest.fixture(scope="function")
def client(db_session):
    """Create test client with database dependency override"""
    def override_get_db():
        try:
            yield db_session
        finally:
            pass
    
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()

@pytest.fixture
def sample_user_data():
    """Sample user data for testing"""
    return {
        "full_name": "Test Scout",
        "email": "scout@test.com",
        "password": "testpassword123",
        "role": "Scout",
        "phone_number": "5551234567"
    }

@pytest.fixture
def sample_player_data():
    """Sample player data for testing"""
    return {
        "name": "Talented Player",
        "age": 18,
        "position": "Forvet",
        "pace": 85,
        "finishing": 80,
        "dribbling": 82,
        "positioning": 78,
        "vision": 70,
        "passing": 72,
        "ball_control": 79,
        "stamina": 75,
        "tackling": 60,
        "marking": 58,
        "strength": 65,
        "jumping": 70,
        "gk_reflexes": 50,
        "gk_diving": 50,
        "gk_handling": 50,
        "gk_positioning": 50,
        "gk_kicking": 50
    }

@pytest.fixture
def sample_rating_data():
    """Sample rating data for testing"""
    return {
        "pac": 80,
        "sho": 75,
        "pas": 78,
        "dri": 76,
        "def": 65,
        "phy": 70
    }
