#!/usr/bin/env python3
"""
Test script for OpenAI API integration in the Redmine MCP Extension.

Usage:
    python scripts/test_openai_api.py [--verbose]
    
Environment Variables:
    OPENAI_API_KEY - If set, this API key will be used instead of reading from credentials.yaml
"""

import os
import sys
import yaml
import argparse

def parse_args():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(description="Test OpenAI API integration for Redmine MCP Extension")
    parser.add_argument("--verbose", "-v", action="store_true", 
                      help="Enable verbose output")
    return parser.parse_args()

def load_credentials():
    """Load credentials from credentials.yaml file"""
    try:
        with open("credentials.yaml", "r") as f:
            credentials = yaml.safe_load(f)
            return credentials
    except Exception as e:
        print(f"Error reading credentials.yaml: {e}")
        return {}

def get_openai_api_key():
    """Get OpenAI API key from environment or credentials file"""
    # First check environment variable
    api_key = os.environ.get("OPENAI_API_KEY")
    
    if api_key:
        print("Using OpenAI API key from environment variable")
        return api_key
    
    # Then check credentials.yaml
    credentials = load_credentials()
    
    # Try both flattened and nested structures
    api_key = credentials.get("openai_api_key")
    if not api_key and "openai" in credentials:
        api_key = credentials["openai"].get("api_key")
        
    if api_key and api_key != "your_openai_api_key_here":
        print("Using OpenAI API key from credentials.yaml")
        return api_key
    
    return None

def test_openai_connection(api_key, verbose=False):
    """Test connection to OpenAI API using GPT-4o model"""
    print("Testing OpenAI API connection...")
    
    try:
        # Dynamically import openai to avoid errors if not installed
        try:
            import openai
        except ImportError:
            print("❌ OpenAI Python package not installed. Please install it with:")
            print("   pip install openai")
            return False
            
        client = openai.OpenAI(api_key=api_key)
        
        print("Sending request to OpenAI API...")
        # Using the newest model
        response = client.chat.completions.create(
            model="gpt-4o",  # the newest OpenAI model is "gpt-4o" which was released May 13, 2024
            messages=[
                {"role": "user", "content": "Hello, GPT! Please provide a one-sentence response."}
            ],
            max_tokens=50
        )
        
        # If we get here, the request was successful
        print("✅ OpenAI API connection successful!")
        
        if verbose:
            print(f"Response model: {response.model}")
            print(f"Response content: {response.choices[0].message.content}")
        else:
            print(f"Response: '{response.choices[0].message.content.strip()}'")
        
        # Test a structured response as well
        if verbose:
            print("\nTesting structured JSON response...")
            json_response = client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "user", "content": "Generate JSON with fields: name, type, and priority"}
                ],
                response_format={"type": "json_object"},
                max_tokens=100
            )
            print(f"JSON response: {json_response.choices[0].message.content}")
            
        return True
    except ImportError:
        print("❌ OpenAI Python package not installed. Please install it with:")
        print("   pip install openai")
        return False
    except Exception as e:
        print(f"❌ OpenAI API connection failed: {e}")
        if verbose:
            import traceback
            traceback.print_exc()
        return False

def test_openai_api(verbose=False):
    """Test the OpenAI API integration"""
    print("\n=== Testing OpenAI API Integration ===")
    
    # Get API key
    api_key = get_openai_api_key()
    
    if not api_key:
        print("❌ No valid OpenAI API key found in environment or credentials.yaml")
        print("Please set the OPENAI_API_KEY environment variable or add it to credentials.yaml")
        return False
    
    # OpenAI package check is done in the test_openai_connection function
    
    # Test the connection
    return test_openai_connection(api_key, verbose)

def main():
    """Main function"""
    args = parse_args()
    success = test_openai_api(args.verbose)
    
    if success:
        print("\n✅ OpenAI API tests completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ OpenAI API tests failed")
        sys.exit(1)

if __name__ == "__main__":
    main()