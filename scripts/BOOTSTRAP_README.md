# Redmine Bootstrap Scripts

## Overview

These scripts help configure a fresh Redmine instance with the necessary configuration for use with the RedmineMCP extension. They create essential entities in Redmine such as trackers, statuses, and test projects.

## Available Scripts

### Standard Bootstrap Script (requires python-redmine)

```bash
./scripts/bootstrap_redmine.sh
```

### Simplified Bootstrap Script (minimal dependencies)

```bash
./scripts/bootstrap_redmine_simple.sh
```

## Known Limitations

### Tracker Creation via API

Redmine restricts the creation of trackers through its REST API, even for admin users. When running the bootstrap scripts, you'll likely see "403 Forbidden" errors when attempting to create trackers. This is a Redmine limitation, not an issue with the scripts.

### Workarounds

1. **Manual Tracker Creation**:
   - Log in to Redmine at http://localhost:3000 using admin/admin
   - Go to Administration > Trackers
   - Create the three default trackers manually (Bug, Feature, Support)

2. **Pre-configured Database** (Coming Soon):
   - A future update will include a pre-configured database with all required entities
   - This will eliminate the need for manual configuration or API-based setup

## Usage

### Basic Usage

```bash
./scripts/bootstrap_redmine_simple.sh
```

### Advanced Options

```bash
./scripts/bootstrap_redmine_simple.sh --config /path/to/credentials.yaml --verbose
```

### Arguments

- `--config`: Path to credentials.yaml file (default: project root)
- `--verbose`: Enable verbose logging
- `--no-wait`: Don't wait for Redmine to start

## Troubleshooting

### Missing Python Dependencies

If you encounter missing dependency errors:

```bash
python -m pip install --user requests pyyaml
```

For the standard script (if available in your environment):

```bash
python -m pip install --user python-redmine pyyaml
```

### Verifying Redmine Setup

After bootstrap, verify your setup by running the test script:

```bash
python scripts/test_redmine_api_functionality.py
```

If trackers are missing, you'll need to create them manually through the Redmine web interface.
