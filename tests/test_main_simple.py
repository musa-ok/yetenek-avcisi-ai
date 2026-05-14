import pytest
import sys
import os

# Add the project root to the Python path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def test_basic_imports():
    """Test that basic modules can be imported"""
    try:
        from backend.database import Base, engine
        from backend.models import User, Player, Rating
        assert True
    except ImportError as e:
        pytest.fail(f"Import failed: {e}")

def test_database_models():
    """Test database models can be created"""
    from backend.models import User, Player, Rating
    from backend.database import Base
    
    # Test model creation
    user = User(
        full_name="Test User",
        email="test@example.com",
        hashed_password="hashed",
        role="Scout",
        phone_number="5551234567"
    )
    
    player = Player(
        name="Test Player",
        age=20,
        position="Forvet",
        overall_rating=75
    )
    
    rating = Rating(
        reviewer_id=1,
        player_id=1,
        pac=80,
        sho=75,
        pas=78,
        dri=76,
        def_=65,
        phy=70
    )
    
    assert user.full_name == "Test User"
    assert player.name == "Test Player"
    assert rating.pac == 80

def test_fastapi_app_creation():
    """Test FastAPI app can be created"""
    try:
        from backend.main import app
        assert app is not None
        assert app.title == "Yetenek Avcısı API"
    except ImportError as e:
        pytest.fail(f"FastAPI app creation failed: {e}")

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
