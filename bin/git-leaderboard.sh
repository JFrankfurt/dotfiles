#!/bin/bash

# Git Leaderboard Script
# Generates statistics for top contributors over the past week and month

set -e  # Exit on error

# Colors for output formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get current date in YYYY-MM-DD format
CURRENT_DATE=$(date +%Y-%m-%d)

# Calculate dates for time periods
ONE_WEEK_AGO=$(date -d "$CURRENT_DATE -7 days" +%Y-%m-%d)
ONE_MONTH_AGO=$(date -d "$CURRENT_DATE -30 days" +%Y-%m-%d)

# Display script header
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}          GIT CONTRIBUTOR LEADERBOARD         ${NC}"
echo -e "${GREEN}===============================================${NC}"
echo -e "Repository: ${BLUE}$(git remote get-url origin 2>/dev/null || echo "Local repository")${NC}"
echo -e "Current branch: ${BLUE}$(git branch --show-current)${NC}"
echo -e "Generated on: ${BLUE}$CURRENT_DATE${NC}\n"

# Function to generate leaderboard for a given time period
generate_leaderboard() {
    local since_date=$1
    local period_name=$2
    local max_contributors=${3:-10}  # Default to showing top 10 contributors
    
    echo -e "${YELLOW}=== Top Contributors ($period_name) ===${NC}"
    echo -e "${YELLOW}Since: $since_date${NC}\n"
    
    # Commits leaderboard
    echo -e "${BLUE}Commits:${NC}"
    git shortlog -sn --no-merges --since="$since_date" | head -n "$max_contributors" | 
        awk '{printf "  %2d. %-30s %5d commits\n", NR, $2, $1}'
    echo ""
    
    # Lines changed leaderboard
    echo -e "${BLUE}Lines changed (added + deleted):${NC}"
    git log --author=".*" --no-merges --shortstat --since="$since_date" |
        grep -E "files? changed" | awk '{inserted+=$4; deleted+=$6} END {print inserted+deleted}' &>/dev/null
        
    git log --format='%aN' --no-merges --since="$since_date" | sort | uniq -c | sort -nr | head -n "$max_contributors" |
        while read -r count author; do
            # Get lines added/deleted for this author
            stats=$(git log --author="$author" --no-merges --shortstat --since="$since_date" |
                   grep -E "files? changed" | awk '{inserted+=$4; deleted+=$6} END {print inserted, deleted}')
            
            added=$(echo "$stats" | awk '{print $1}')
            deleted=$(echo "$stats" | awk '{print $2}')
            
            # Handle empty values (authors with no actual changes)
            added=${added:-0}
            deleted=${deleted:-0}
            total=$((added + deleted))
            
            printf "  %2d. %-30s %5d lines (+%d/-%d)\n" "$((NR))" "$author" "$total" "$added" "$deleted"
        done
    echo ""
    
    # Files changed leaderboard
    echo -e "${BLUE}Files changed:${NC}"
    git log --format='%aN' --no-merges --since="$since_date" | sort | uniq -c | sort -nr | head -n "$max_contributors" |
        while read -r count author; do
            # Get files changed count for this author
            files=$(git log --author="$author" --no-merges --since="$since_date" --name-only --pretty=format: | sort | uniq | wc -l)
            printf "  %2d. %-30s %5d files\n" "$((NR))" "$author" "$files"
        done
    echo ""
}

# Generate leaderboards for different time periods
generate_leaderboard "$ONE_WEEK_AGO" "Past Week"
echo -e "${GREEN}-----------------------------------------------${NC}\n"
generate_leaderboard "$ONE_MONTH_AGO" "Past Month"

echo -e "\n${GREEN}===============================================${NC}"
echo -e "${GREEN}               END OF REPORT                  ${NC}"
echo -e "${GREEN}===============================================${NC}"