#!/usr/bin/env python3
"""
Unified setup script for the Redmine MCP Extension.
Handles:
- Setting up credentials (Redmine, MCP URL)
- Configuring development environments (local, Docker)
- Validating configurations

Usage:
    python scripts/setup.py credentials - Create/update credentials.yaml file
    python scripts/setup.py validate - Validate the current configuration
    python scripts/setup.py dev - Setup local development environment
    python scripts/setup.py docker - Setup Docker development environment
"""

import os
import sys
import yaml
import argparse
import subprocess
from pathlib import Path

def parse_args():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(description="Setup and configuration utilities for Redmine MCP Extension")
    
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")
    
    # Credentials setup parser
    creds_parser = subparsers.add_parser("credentials", help="Set up credentials.yaml file")
    creds_parser.add_argument("--redmine-url", default="http://localhost:3000",
                           help="Redmine instance URL")
    creds_parser.add_argument("--redmine-api-key", default="YOUR_REDMINE_API_KEY",
                           help="Redmine API key")
    creds_parser.add_argument("--mcp-url", default="http://localhost:9000",
                           help="Claude Desktop MCP service URL")
    creds_parser.add_argument("--llm-provider", default="claude-desktop", choices=["claude-desktop"],
                           help="Default LLM provider to use (only claude-desktop is supported)")
    creds_parser.add_argument("--rate-limit", type=int, default=60,
                           help="API rate limit per minute")
    creds_parser.add_argument("--force", "-f", action="store_true",
                           help="Force overwrite if credentials.yaml exists")
                           
    # Validation parser
    validate_parser = subparsers.add_parser("validate", help="Validate configurations")
    
    # Development environment setup parser
    dev_parser = subparsers.add_parser("dev", help="Set up local development environment")
    
    # Docker environment setup parser
    docker_parser = subparsers.add_parser("docker", help="Set up Docker development environment")
    docker_parser.add_argument("--build", "-b", action="store_true",
                            help="Build Docker images")
    
    args = parser.parse_args()
    
    # If no command specified, show help and exit
    if not args.command:
        parser.print_help()
        sys.exit(1)
        
    return args

def setup_credentials(args):
    """Set up credentials.yaml file"""
    # Check if credentials.yaml already exists
    if os.path.exists("credentials.yaml") and not args.force:
        overwrite = input("credentials.yaml already exists. Overwrite? (y/N): ")
        if overwrite.lower() != "y":
            print("Using existing credentials.yaml file")
            return
    
    # Validate Redmine URL format (minimal check)
    if not args.redmine_url.startswith(("http://", "https://")):
        print("ERROR: Invalid Redmine URL format. Must start with http:// or https://")
        sys.exit(1)
        
    # Ensure URL doesn't end with a slash
    redmine_url = args.redmine_url
    if redmine_url.endswith("/"):
        redmine_url = redmine_url[:-1]
    
    # Set MCP URL with default localhost:9000 if not provided
    mcp_url = getattr(args, 'mcp_url', 'http://localhost:9000')
    
    # Create credentials.yaml file
    credentials = {
        "redmine_url": redmine_url,
        "redmine_api_key": args.redmine_api_key,
        "llm_provider": "claude-desktop",  # We only support claude-desktop now
        "mcp_url": mcp_url,
        "rate_limit_per_minute": args.rate_limit
    }
    
    print("Creating credentials.yaml file...")
    with open("credentials.yaml", "w") as f:
        yaml.dump(credentials, f, default_flow_style=False)
    
    # Create credentials.yaml.example if it doesn't exist
    if not os.path.exists("credentials.yaml.example"):
        example_creds = credentials.copy()
        example_creds["redmine_api_key"] = "your_redmine_api_key_here"
        
        with open("credentials.yaml.example", "w") as f:
            yaml.dump(example_creds, f, default_flow_style=False)
    
    print("✅ credentials.yaml created successfully")
    
    # Print next steps
    print("""
🔑 Credential setup complete!

✨ Next steps:
   1. Make sure Redmine is running at {}
   2. Add your actual API key to credentials.yaml:
      - Redmine API key: Get from Redmine > My account > API access key
   3. Make sure Claude Desktop with MCP is running at {}
   4. Start the application with: flask run --host=0.0.0.0 --port=9000
""".format(redmine_url, mcp_url))

def validate_config():
    """Validate configuration file"""
    print("Validating configuration...")
    
    # Check if credentials.yaml exists
    if not os.path.exists("credentials.yaml"):
        print("❌ credentials.yaml not found")
        print("Run 'python scripts/setup.py credentials' to create it")
        return False
    
    # Load and check credentials
    try:
        with open("credentials.yaml", "r") as f:
            credentials = yaml.safe_load(f)
            
        # Check required fields
        required_fields = ["redmine_url", "redmine_api_key"]
        for field in required_fields:
            if field not in credentials:
                print(f"❌ Missing required field: {field}")
                return False
            
        # Check Redmine URL format
        if not credentials["redmine_url"].startswith(("http://", "https://")):
            print("❌ Invalid Redmine URL format. Must start with http:// or https://")
            return False
            
        # Check LLM provider is claude-desktop
        llm_provider = credentials.get("llm_provider", "claude-desktop")
        if llm_provider != "claude-desktop":
            print("❌ Only 'claude-desktop' is supported as LLM provider")
            return False
            
        # Check if MCP URL is present
        if "mcp_url" not in credentials:
            print("⚠️ MCP URL not specified, will use default: http://localhost:9000")
        elif not credentials["mcp_url"].startswith(("http://", "https://")):
            print("❌ Invalid MCP URL format. Must start with http:// or https://")
            return False
        
        print("✅ Configuration validated successfully")
        return True
    except Exception as e:
        print(f"❌ Error validating configuration: {e}")
        return False

def setup_dev_environment():
    """Set up local development environment"""
    print("Setting up local development environment...")
    
    # Check if Python dependencies are installed
    required_packages = ["flask", "requests"]
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package)
        except ImportError:
            missing_packages.append(package)
    
    if not missing_packages:
        print("✅ Required Python packages already installed")
    else:
        print(f"❌ Missing Python dependencies: {', '.join(missing_packages)}")
        print("Installing required packages...")
        subprocess.run([sys.executable, "-m", "pip", "install", "-e", "."])
    
    # Check if credentials are set up
    if not os.path.exists("credentials.yaml"):
        print("⚠️ credentials.yaml not found")
        setup_creds = input("Would you like to set up credentials now? (y/N): ")
        if setup_creds.lower() == "y":
            creds_args = argparse.Namespace(
                redmine_url="http://localhost:3000",
                redmine_api_key="YOUR_REDMINE_API_KEY",
                mcp_url="http://localhost:9000",
                llm_provider="claude-desktop",
                rate_limit=60,
                force=False
            )
            setup_credentials(creds_args)
    
    print("""
✅ Development environment setup complete!

✨ To start the application:
   1. Ensure credentials.yaml is properly configured
   2. Run: flask run --host=0.0.0.0 --port=9000
   
   Or use the convenience script:
   ./start_local_dev.sh
""")

def setup_docker_environment(build=False):
    """Set up Docker development environment"""
    print("Setting up Docker development environment...")
    
    # Check if Docker is installed
    try:
        subprocess.run(["docker", "--version"], check=True, capture_output=True)
    except FileNotFoundError:
        print("❌ Docker not found. Please install Docker first.")
        return False
    except subprocess.CalledProcessError:
        print("❌ Error checking Docker installation.")
        return False
    
    # Check if docker-compose is installed
    try:
        subprocess.run(["docker-compose", "--version"], check=True, capture_output=True)
    except FileNotFoundError:
        print("❌ docker-compose not found. Please install docker-compose first.")
        return False
    except subprocess.CalledProcessError:
        print("❌ Error checking docker-compose installation.")
        return False
    
    # Check if credentials are set up
    if not os.path.exists("credentials.yaml"):
        print("⚠️ credentials.yaml not found")
        setup_creds = input("Would you like to set up credentials now? (y/N): ")
        if setup_creds.lower() == "y":
            creds_args = argparse.Namespace(
                redmine_url="http://redmine:3000",  # Use Docker service name
                redmine_api_key="YOUR_REDMINE_API_KEY",
                mcp_url="http://localhost:9000",  # MCP typically runs on host, not in Docker
                llm_provider="claude-desktop",
                rate_limit=60,
                force=False
            )
            setup_credentials(creds_args)
    
    # Build Docker images if requested
    if build:
        print("Building Docker images...")
        try:
            subprocess.run(["docker-compose", "build"], check=True)
            print("✅ Docker images built successfully")
        except subprocess.CalledProcessError as e:
            print(f"❌ Error building Docker images: {e}")
            return False
    
    print("""
✅ Docker environment setup complete!

✨ To start the application in Docker:
   docker-compose up -d
   
   To view logs:
   docker-compose logs -f
   
   To stop:
   docker-compose down
""")
    return True


def main():
    """Main function"""
    args = parse_args()
    
    if args.command == "credentials":
        setup_credentials(args)
    elif args.command == "validate":
        validate_config()
    elif args.command == "dev":
        setup_dev_environment()
    elif args.command == "docker":
        setup_docker_environment(args.build)

if __name__ == "__main__":
    main()