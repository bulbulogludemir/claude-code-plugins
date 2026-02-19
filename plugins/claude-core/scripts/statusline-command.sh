#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Pastel colors (will be dimmed by terminal)
PASTEL_PURPLE='\033[38;2;189;147;249m'  # Soft purple for git branch
PASTEL_CYAN='\033[38;2;139;233;253m'    # Soft cyan for context window
PASTEL_PINK='\033[38;2;255;121;198m'    # Soft pink for push status
PASTEL_GREEN='\033[38;2;80;250;123m'    # Soft green for bar
RESET='\033[0m'

# Git information with pastel colors
git_info=""
if cd "$cwd" 2>/dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    # Get current branch
    branch=$(git -c core.fileMode=false rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Get push status (ahead/behind)
    upstream=$(git -c core.fileMode=false rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    if [ -n "$upstream" ]; then
        ahead=$(git -c core.fileMode=false rev-list --count ${upstream}..HEAD 2>/dev/null || echo "0")
        behind=$(git -c core.fileMode=false rev-list --count HEAD..${upstream} 2>/dev/null || echo "0")

        push_status=""
        if [ "$ahead" -gt 0 ]; then
            push_status=" ${PASTEL_PINK}↑$ahead${RESET}"
        fi
        if [ "$behind" -gt 0 ]; then
            push_status="${push_status} ${PASTEL_PINK}↓$behind${RESET}"
        fi

        git_info="${PASTEL_PURPLE}$branch${RESET}${push_status}"
    else
        git_info="${PASTEL_PURPLE}$branch${RESET}"
    fi
fi

# Context window visual bar with pastel colors
context_bar=""
if [ -n "$used_pct" ]; then
    # Convert percentage to integer
    used_int=$(printf "%.0f" "$used_pct")

    # Create a 10-character bar
    filled=$((used_int / 10))
    empty=$((10 - filled))

    # Choose color based on usage
    if [ "$used_int" -lt 70 ]; then
        bar_color="${PASTEL_GREEN}"
    elif [ "$used_int" -lt 85 ]; then
        bar_color="${PASTEL_CYAN}"
    else
        bar_color="${PASTEL_PINK}"
    fi

    bar=""
    for ((i=0; i<filled; i++)); do
        bar="${bar}█"
    done
    for ((i=0; i<empty; i++)); do
        bar="${bar}░"
    done

    context_bar="${PASTEL_CYAN}context ${bar_color}[${bar}${RESET} ${PASTEL_CYAN}${used_int}%${bar_color}]${RESET}"
fi

# TypeScript error count (from async hook cache)
PROJECT_HASH=$(echo "$cwd" | md5 2>/dev/null | cut -c1-8 || echo "$cwd" | md5sum 2>/dev/null | cut -c1-8)
TEMP_DIR="/tmp/claude-$PROJECT_HASH"
tsc_info=""
if [ -f "$TEMP_DIR/tsc-errors.log" ] && [ -s "$TEMP_DIR/tsc-errors.log" ]; then
    TSC_COUNT=$(grep -c "error TS" "$TEMP_DIR/tsc-errors.log" 2>/dev/null || echo "0")
    if [ "$TSC_COUNT" -gt 0 ]; then
        tsc_info="${PASTEL_PINK}tsc:${TSC_COUNT}err${RESET}"
    fi
fi

# Uncommitted changes count
dirty_info=""
if cd "$cwd" 2>/dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    DIRTY_COUNT=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    STAGED_COUNT=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    TOTAL_DIRTY=$((DIRTY_COUNT + STAGED_COUNT))
    if [ "$TOTAL_DIRTY" -gt 0 ]; then
        dirty_info="${PASTEL_PINK}${TOTAL_DIRTY}∆${RESET}"
    fi
fi

# Active team/agent count
team_info=""
if [ -d "$HOME/.claude/teams" ]; then
    TEAM_COUNT=$(ls -d "$HOME/.claude/teams"/*/ 2>/dev/null | wc -l | tr -d ' ')
    if [ "$TEAM_COUNT" -gt 0 ]; then
        team_info="${PASTEL_CYAN}team:${TEAM_COUNT}${RESET}"
    fi
fi

# Session name from env var
session_info=""
if [ -n "$CLAUDE_SESSION_NAME" ]; then
    session_info="${PASTEL_CYAN}${CLAUDE_SESSION_NAME}${RESET}"
fi

# Build status line
status_parts=()

if [ -n "$session_info" ]; then
    status_parts+=("$(printf "%b" "$session_info")")
fi

if [ -n "$git_info" ]; then
    status_parts+=("$(printf "%b" "$git_info")")
fi

if [ -n "$dirty_info" ]; then
    status_parts+=("$(printf "%b" "$dirty_info")")
fi

if [ -n "$tsc_info" ]; then
    status_parts+=("$(printf "%b" "$tsc_info")")
fi

if [ -n "$team_info" ]; then
    status_parts+=("$(printf "%b" "$team_info")")
fi

if [ -n "$context_bar" ]; then
    status_parts+=("$(printf "%b" "$context_bar")")
fi

# Join with separator
if [ ${#status_parts[@]} -gt 0 ]; then
    printf "%s" "${status_parts[0]}"
    for ((i=1; i<${#status_parts[@]}; i++)); do
        printf " ${PASTEL_CYAN}•${RESET} %s" "${status_parts[$i]}"
    done
fi
