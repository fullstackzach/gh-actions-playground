#!/bin/bash

# Reqires atleast one jira ticket in the format AUS-1234 on either a branch or commit message

# Checkout branch
git checkout -q $1

# Set variables
BASE_BRANCH=$2
msg_regex='AUS\-[0-9]+'
skip_regex='\[SKIP JIRA\]'

# Initialize invalidCommit as false, will be set to true by any invalid commits
# Find current branch name
CURRENT_BRANCH=$(git branch --show-current)

#echo "Current branch is:" $CURRENT_BRANCH
# Find hash of commit most common ancestor, e.g. where branch began
BRANCH_MERGE_BASE=$(git merge-base ${BASE_BRANCH} ${CURRENT_BRANCH})
# echo "Branch merge base hash is:" $BRANCH_MERGE_BASE
# Find all commits since common ancestor
BRANCH_COMMITS=$(git rev-list ${BRANCH_MERGE_BASE}..HEAD)

# Check every commit message since ancestor for regex matchs
for commit in $BRANCH_COMMITS; do
    COMMIT_MSG_UPPER=$(git log --max-count=1 --format=%B $commit | tr '[a-z]' '[A-Z]')
    
    if echo $COMMIT_MSG_UPPER | grep -iqE "$skip_regex"; then
       echo "************"
       echo "[skip jira] detected, skipping commit linting"
       echo "************"
       exit 0
    fi

    if echo $COMMIT_MSG_UPPER | grep -iqE "$msg_regex"; then
       echo "************"
       echo "Jira ticket # found in a commit mesage 👍🏻"
       echo "************"
       exit 0
    fi
done

CURRENT_BRANCH_UPPER=$(echo $CURRENT_BRANCH | tr '[a-z]' '[A-Z]')

if echo $CURRENT_BRANCH_UPPER | grep -iqE "$skip_regex"; then
    echo "************"
    echo "[skip jira] detected, skipping commit linting"
    echo "************"
    exit 0
fi

if echo $CURRENT_BRANCH_UPPER | grep -iqE "$msg_regex"; then
    echo "************"
    echo "Jira ticket # found in a branch name 👍🏻"
    echo "************"
    exit 0
fi

# If we made it this far, no JIRA ticket # was detected in a commit or branch, print the reject message and fail the job

echo "⛔️ At least one commit OR your branch name must include a JIRA ticket number e.g. \"AUS-1234\". This can be anywhere in your commit"
echo "You can skip this whole step if necessary by running \"git commit --amend\" and add \"[skip jira]\" in your last commit message, and force-push"
echo "Please fix the commit message and push again."
echo "https://help.github.com/en/articles/changing-a-commit-message"
echo "************"
exit 1