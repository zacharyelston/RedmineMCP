from setuptools import setup

# This file is maintained for compatibility with tools that don't yet support pyproject.toml
# The actual metadata is stored in pyproject.toml

setup(
    name="redmine-mcp-extension",
    version="0.1.0",
    py_modules=[
        "app",
        "main",
        "models",
        "routes",
        "mcp",
        "llm_api",
        "llm_factory",
        "redmine_api",
        "openai_api",
        "utils",
    ],
    python_requires=">=3.9",
)