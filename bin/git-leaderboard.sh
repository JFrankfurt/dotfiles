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

# Calculate dates for time periods - cross-platform compatible
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    ONE_WEEK_AGO=$(date -v -7d +%Y-%m-%d)
    ONE_MONTH_AGO=$(date -v -30d +%Y-%m-%d)
else
    # Linux and others
    ONE_WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -d "-7 days" +%Y-%m-%d 2>/dev/null || date --date="7 days ago" +%Y-%m-%d)
    ONE_MONTH_AGO=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -d "-30 days" +%Y-%m-%d 2>/dev/null || date --date="30 days ago" +%Y-%m-%d)
fi

# Display script header
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}          GIT CONTRIBUTOR LEADERBOARD         ${NC}"
echo -e "${GREEN}===============================================${NC}"
echo -e "Repository: ${BLUE}$(git remote get-url origin 2>/dev/null || echo "Local repository")${NC}"
echo -e "Current branch: ${BLUE}$(git branch --show-current)${NC}"
echo -e "Generated on: ${BLUE}$CURRENT_DATE${NC}\n"

# Create a temporary directory for output
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Function to gather contributor data in parallel
gather_contributor_data() {
    local since_date=$1
    local output_dir="$2"
    local max_contributors=$3
    
    # Ensure consistent sorting regardless of locale
    export LC_ALL=C
    
    # Get all authors and their emails for exact matching
    git log --no-merges --since="$since_date" --format='%aN <%aE>' | sort -u > "$output_dir/authors.txt"
    
    # Process commits count - use a different format to ensure names are captured correctly
    git shortlog -sne --no-merges --since="$since_date" > "$output_dir/commits.txt"
    
    # Process all authors in parallel
    cat "$output_dir/authors.txt" | while read -r author_email; do
        # Extract author name and email for exact matching
        author=$(echo "$author_email" | sed -E 's/^(.+) <.+>$/\1/')
        email=$(echo "$author_email" | sed -E 's/^.+ <(.+)>$/\1/')
        
        # Escape author name for use in git --author
        author_pattern=$(echo "$author" | sed 's/[[\.*^$/]/\\&/g')
        
        # Get lines added/deleted in one pass
        git log --author="$author_pattern" --author="$email" --no-merges --shortstat --since="$since_date" | 
            grep -E "files? changed" | 
            awk '{ files+=$1; inserted+=$4; deleted+=$6 } END { print files, inserted, deleted }' > "$output_dir/${author// /_}.stats"
            
        # Get unique files changed
        git log --author="$author_pattern" --author="$email" --no-merges --name-only --pretty=format: --since="$since_date" | 
            sort -u | wc -l > "$output_dir/${author// /_}.files"
    done
    
    # Wait for all background processes to complete
    wait
    
    # Combine data into a single file
    for author_file in "$output_dir"/*.stats; do
        if [ -f "$author_file" ]; then
            author=$(basename "$author_file" .stats | tr '_' ' ')
            stats=$(cat "$author_file")
            files=$(cat "${author_file%.stats}.files")
            
            # Format: author|files_changed|lines_added|lines_deleted|files_count
            files_changed=$(echo "$stats" | awk '{print $1}' || echo 0)
            lines_added=$(echo "$stats" | awk '{print $2}' || echo 0)
            lines_deleted=$(echo "$stats" | awk '{print $3}' || echo 0)
            
            # Handle empty values
            files_changed=${files_changed:-0}
            lines_added=${lines_added:-0}
            lines_deleted=${lines_deleted:-0}
            files=${files:-0}
            
            echo "$author|$files_changed|$lines_added|$lines_deleted|$files" >> "$output_dir/combined.txt"
        fi
    done
}

# Function to generate leaderboard for a given time period
generate_leaderboard() {
    local since_date=$1
    local period_name=$2
    local max_contributors=${3:-10}  # Default to showing top 10 contributors
    local output_dir="$TEMP_DIR/$period_name"
    
    mkdir -p "$output_dir"
    
    echo -e "${YELLOW}=== Top Contributors ($period_name) ===${NC}"
    echo -e "${YELLOW}Since: $since_date${NC}\n"
    
    # Gather data for all metrics in parallel
    gather_contributor_data "$since_date" "$output_dir" "$max_contributors"
    
    # Commits leaderboard
    echo -e "${BLUE}Commits:${NC}"
    if [ -f "$output_dir/commits.txt" ]; then
        # Properly handle multi-word names by using proper field separation
        # The format of git shortlog -sne is: number<tab>name<space><email>
        # We need to extract just the number and name
        cat "$output_dir/commits.txt" | head -n "$max_contributors" | 
            # Use a more compatible Perl syntax without 'else if'
            perl -ne 'if (/^\s*(\d+)\s+(.+?)\s+<.*>$/) { print "$1|$2\n"; } elsif (/^\s*(\d+)\s+(.+)$/) { print "$1|$2\n"; }' | 
            awk -F'|' '{
                count = $1;
                author = $2;
                # Truncate long names
                display_name = (length(author) > 30) ? substr(author, 1, 27) "..." : author;
                printf "  %2d. %-30s %5d commits\n", NR, display_name, count;
            }'
    else
        echo "  No commit data available"
    fi
    echo ""
    
    # Lines changed leaderboard - sort by total lines changed (sum of added and deleted)
    echo -e "${BLUE}Lines changed (added + deleted):${NC}"
    if [ -f "$output_dir/combined.txt" ]; then
        # Sort by lines changed (added + deleted)
        cat "$output_dir/combined.txt" | 
            awk -F'|' '{print $0, $3+$4}' | sort -k6,6nr | head -n "$max_contributors" | 
            awk -F'|' '{
                author = $1;
                added = $3;
                deleted = $4;
                total = added + deleted;
                # Truncate long names
                display_name = (length(author) > 30) ? substr(author, 1, 27) "..." : author;
                printf "  %2d. %-30s %7d lines (+%d/-%d)\n", NR, display_name, total, added, deleted;
            }'
    else
        echo "  No line data available"
    fi
    echo ""
    
    # Files changed leaderboard
    echo -e "${BLUE}Files changed:${NC}"
    if [ -f "$output_dir/combined.txt" ]; then
        # Sort by files count
        cat "$output_dir/combined.txt" | 
            sort -t'|' -k5,5nr | head -n "$max_contributors" | 
            awk -F'|' '{
                author = $1;
                files = $5;
                # Truncate long names
                display_name = (length(author) > 30) ? substr(author, 1, 27) "..." : author;
                printf "  %2d. %-30s %5d files\n", NR, display_name, files;
            }'
    else
        echo "  No file data available"
    fi
    echo ""
}

# Add a help option
show_help() {
    echo "Git Leaderboard - Show contribution statistics for your repository"
    echo ""
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -w, --week DAYS     Set custom week period (default: 7 days)"
    echo "  -m, --month DAYS    Set custom month period (default: 30 days)"
    echo "  -n, --number N      Show top N contributors (default: 10)"
    echo "  -h, --help          Display this help message"
    echo ""
    exit 0
}

# Parse command line arguments
WEEK_DAYS=7
MONTH_DAYS=30
MAX_CONTRIBUTORS=10

while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--week)
            WEEK_DAYS="$2"
            shift 2
            ;;
        -m|--month)
            MONTH_DAYS="$2"
            shift 2
            ;;
        -n|--number)
            MAX_CONTRIBUTORS="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Recalculate dates if custom periods provided
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    ONE_WEEK_AGO=$(date -v -${WEEK_DAYS}d +%Y-%m-%d)
    ONE_MONTH_AGO=$(date -v -${MONTH_DAYS}d +%Y-%m-%d)
else
    # Linux and others
    ONE_WEEK_AGO=$(date -d "${WEEK_DAYS} days ago" +%Y-%m-%d 2>/dev/null || date -d "-${WEEK_DAYS} days" +%Y-%m-%d 2>/dev/null || date --date="${WEEK_DAYS} days ago" +%Y-%m-%d)
    ONE_MONTH_AGO=$(date -d "${MONTH_DAYS} days ago" +%Y-%m-%d 2>/dev/null || date -d "-${MONTH_DAYS} days" +%Y-%m-%d 2>/dev/null || date --date="${MONTH_DAYS} days ago" +%Y-%m-%d)
fi

# Generate leaderboards for different time periods
generate_leaderboard "$ONE_WEEK_AGO" "Past Week" "$MAX_CONTRIBUTORS"
echo -e "${GREEN}-----------------------------------------------${NC}\n"
generate_leaderboard "$ONE_MONTH_AGO" "Past Month" "$MAX_CONTRIBUTORS"