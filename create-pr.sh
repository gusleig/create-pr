#!/bin/bash

# Configuration variables
JIRA_BASE_URL="https://pepsico-ecomm.atlassian.net/browse"
DEFAULT_REVIEWERS="lsch21"  # Set your default reviewers here

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

debug() {
    echo "DEBUG - $1"
}

# Help function
show_help() {
    echo "Usage: create-pr [options] TICKET-123 [reviewer1,reviewer2,...]"
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would happen without creating the PR"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  create-pr TICKET-123"
    echo "  create-pr --dry-run TICKET-123"
    echo "  create-pr TICKET-123 \"reviewer1,reviewer2\""
}

# Parse arguments
DRY_RUN=false
JIRA_TICKET=""
REVIEWERS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            if [ -z "$JIRA_TICKET" ]; then
                JIRA_TICKET=$1
            elif [ -z "$REVIEWERS" ]; then
                REVIEWERS=$1
            fi
            shift
            ;;
    esac
done

if [ -z "$JIRA_TICKET" ]; then
    log "❌ Error: Missing Jira ticket number"
    show_help
    exit 1
fi

# Set reviewers to default if not provided
REVIEWERS=${REVIEWERS:-$DEFAULT_REVIEWERS}

if [ "$DRY_RUN" = true ]; then
    log "🏃 DRY RUN MODE - No changes will be made"
fi

log "Script started"
log "🎟️  Jira ticket: $JIRA_TICKET"
log "👥 Reviewers: $REVIEWERS"

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
log "🌿 Current branch: $CURRENT_BRANCH"

# Determine base branch (main or master)
if git rev-parse --verify main >/dev/null 2>&1; then
    BASE_BRANCH="main"
else
    BASE_BRANCH="master"
fi
log "📍 Base branch detected: $BASE_BRANCH"

# Debug git log command
debug "Executing git log for commits..."
debug "Command: git log $BASE_BRANCH..$CURRENT_BRANCH --format=%B"
debug "Commits found:"
git log $BASE_BRANCH..$CURRENT_BRANCH --format=%B

# Get the first commit message with better error handling
FIRST_COMMIT_MSG=$(git log $BASE_BRANCH..$CURRENT_BRANCH --format=%B | grep . | head -n 1)
if [ -z "$FIRST_COMMIT_MSG" ]; then
    log "⚠️  No commits found between $BASE_BRANCH and $CURRENT_BRANCH"
    log "Checking for any commits in current branch..."
    FIRST_COMMIT_MSG=$(git log -1 --format=%B)
    if [ -z "$FIRST_COMMIT_MSG" ]; then
        log "⚠️  No commits found at all. Using branch name as fallback."
        FIRST_COMMIT_MSG=$CURRENT_BRANCH
    fi
fi
log "📝 Commit message: $FIRST_COMMIT_MSG"

# Check remote branch
log "Checking if branch exists on remote..."
if ! git ls-remote --heads origin $CURRENT_BRANCH | grep -q $CURRENT_BRANCH; then
    log "🔄 Branch not found on remote."
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Would push branch to remote"
    else
        log "Pushing to origin..."
        if git push -u origin $CURRENT_BRANCH; then
            log "✅ Successfully pushed branch to remote"
        else
            log "❌ Failed to push branch to remote"
            exit 1
        fi
    fi
else
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Would push any new commits to remote"
    else
        log "Branch exists on remote, pushing any new commits..."
        if git push origin $CURRENT_BRANCH; then
            log "✅ Successfully pushed new commits to remote"
        else
            log "❌ Failed to push new commits to remote"
            exit 1
        fi
    fi
fi

# Create PR content
log "Creating PR content..."
PR_TITLE="$FIRST_COMMIT_MSG"
PR_BODY="# Purpose

$FIRST_COMMIT_MSG

# Jira Card

[$JIRA_TICKET]($JIRA_BASE_URL/$JIRA_TICKET)"

if [ "$DRY_RUN" = true ]; then
    log "DRY RUN: Would create PR with following details:"
    echo "----------------------------------------"
    echo "Title: $PR_TITLE"
    echo ""
    echo "Body:"
    echo "$PR_BODY"
    echo ""
    echo "Reviewers: $REVIEWERS"
    echo "Draft: yes"
    echo "----------------------------------------"
else
    log "Creating PR with GitHub CLI..."
    # Create PR using GitHub CLI and capture the URL
    PR_URL=$(gh pr create \
        --title "$PR_TITLE" \
        --body "$PR_BODY" \
        --reviewer "$REVIEWERS" \
        --draft)

    # Check if PR creation was successful
    if [ $? -eq 0 ]; then
        log "✅ Pull request created successfully!"
        log "👥 Assigned reviewers: $REVIEWERS"
        log "🔗 Pull request URL: $PR_URL"

        # Open the PR in the default browser
        log "Opening PR in browser..."
        open "$PR_URL"
    else
        log "❌ Error: Failed to create pull request"
        exit 1
    fi
fi

log "Script completed successfully"
