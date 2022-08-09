#!/bin/bash

# Checkout branch
git checkout -q $1

# Set variables
BASE_BRANCH=$2
msg_regex='(AAA|BBB|CCC)\-[0-9]+'
skip_regex='\[SKIP JIRA\]'

# Initialize invalidCommit as false, will be set to true by any invalid commits
invalidCommit=false
# Find current branch name
CURRENT_BRANCH=$(git branch --show-current)

#echo "Current branch is:" $CURRENT_BRANCH
# Find hash of commit most common ancestor, e.g. where branch began
BRANCH_MERGE_BASE=$(git merge-base ${BASE_BRANCH} ${CURRENT_BRANCH})
#echo "Branch merge base hash is:" $BRANCH_MERGE_BASE
# Find all commits since common ancestor
BRANCH_COMMITS=$(git rev-list ${BRANCH_MERGE_BASE}..HEAD)

#echo $BRANCH_COMMITS

# Check every commit message since ancestor for regex match
for commit in $BRANCH_COMMITS; do
    CURRENT_COMMIT_MSG=$(git log --max-count=1 --format=%B $commit | tr '[a-z]' '[A-Z]')
    
    if echo $COMMIT_MSG_UPPER | grep -iqE "$skip_regex"; then
       echo "************"
       echo "[skip jira] detected, skipping commit linting"
       echo "************"
       exit 0
    fi

    if echo $COMMIT_MSG_UPPER | grep -iqE "$msg_regex"; then
        : #If commit matches regex, commit is valid, do nothing
    else
        # If commit doesn't match regex, commit isn't valid, print commit info
        echo "************"
        printf "Invalid commit message: \"%s\"\n" "$(git log --max-count=1 --format=%B $commit)" 
        printf "commit sha: %s\n" "$commit"
        echo "************"
        
        # Set this variable to trigger rejection if any commit fails regex
        invalidCommit=true
    fi
done

# If any commit are invalid, print the reject message
if [ "$invalidCommit" == true ]; then
    echo "Commit messages must include a JIRA ticket number e.g. \"AAA-1234\". This can be anywhere in your commit"
    echo "You can skip this step if necessary by running \"git commit --amend\" and add \"[skip jira]\" in your commit message"
    echo "Please fix the commit message(s) and push again."
    echo "https://help.github.com/en/articles/changing-a-commit-message"
    echo "************"
    exit 1
elif [ "$invalidCommit" == false ]; then
    echo "************"
    echo "All commits are valid"
    echo "************"
    exit 0
fi