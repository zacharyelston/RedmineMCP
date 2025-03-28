from app import app
from utils import update_config_from_credentials

# Initialize application when it starts
with app.app_context():
    # Try to load configuration from credentials.yaml
    success, message = update_config_from_credentials()
    print(f"Loading credentials: {message}")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
