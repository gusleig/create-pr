# GitHub PR Creator Script

A Bash script that automates creating GitHub pull requests with Jira ticket integration.

## Features

- Automatic PR creation with standardized format
- Jira ticket integration
- Default reviewers configuration
- Automatic branch pushing
- Dry run mode for testing
- Base branch auto-detection (main/master)
- Detailed logging

## Prerequisites

- GitHub CLI (`gh`)
- Git
- macOS (for `open` command)

## Installation

```bash
git clone https://github.com/gusleig/create-pr.git ~/code/create-pr
chmod +x ~/code/create-pr/create-pr.sh
sudo ln -s ~/code/create-pr/create-pr.sh /usr/local/bin/create-pr
```

## Configuration
Set those env variables:

```
export JIRA_URL="your-url"
export REVIEWERS="user1,user2"
```

Edit these variables in the script:
```

```bash
JIRA_BASE_URL="https://your-jira-instance.atlassian.net/browse"
DEFAULT_REVIEWERS="default-username1,default-username2"
```

## Usage

```bash
# Create PR
create-pr TICKET-123

# Create PR with specific reviewers
create-pr TICKET-123 "reviewer1,reviewer2"

# Test run without creating PR
create-pr --dry-run TICKET-123

# Show help
create-pr --help
```

## PR Format

```markdown
Title: <first commit message>

# Purpose

<first commit message>

# Jira Card

[TICKET-123](https://your-jira-instance.atlassian.net/browse/TICKET-123)
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
