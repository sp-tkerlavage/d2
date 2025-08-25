#!/usr/bin/env bash

# Common functions and variables for D2 diagram scripts
# Source this file in other scripts: source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Find project root by looking for .git directory
find_project_root() {
    local current="$(pwd)"
    while [ "$current" != "/" ]; do
        if [ -d "$current/.git" ]; then
            echo "$current"
            return 0
        fi
        current="$(dirname "$current")"
    done
    echo "$(pwd)"
}

# Load environment variables from .env file (handles special characters)
load_env() {
    local env_file="${1:-.env}"
    if [ -f "$env_file" ]; then
        echo -e "${GREEN}Loading environment from $env_file${NC}"
        # Use set -a to auto-export variables, then source the file
        set -a
        source "$env_file"
        set +a
    elif [ -f ".envrc" ]; then
        echo -e "${GREEN}Loading environment from .envrc${NC}"
        source .envrc
    fi
}

# Determine the layout engine to use (TALA or DAGRE)
determine_layout_engine() {
    local layout_engine="dagre"
    
    if [ -n "$TSTRUCT_TOKEN" ]; then
        # Check if TALA plugin exists
        local tala_plugin_path="$HOME/.local/bin/d2plugin-tala"
        if [ ! -f "$tala_plugin_path" ]; then
            tala_plugin_path="$(which d2plugin-tala 2>/dev/null || echo '')"
        fi
        
        if [ -n "$tala_plugin_path" ] && [ -f "$tala_plugin_path" ]; then
            # Test TALA with the token
            if echo "test: hello" | TSTRUCT_TOKEN="$TSTRUCT_TOKEN" D2_LAYOUT=tala d2 - - >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Using TALA layout engine${NC}" >&2
                layout_engine="tala"
            else
                echo -e "${YELLOW}⚠ TALA test failed, using DAGRE${NC}" >&2
            fi
        else
            echo -e "${YELLOW}⚠ TALA plugin not found, using DAGRE${NC}" >&2
        fi
    else
        echo -e "${YELLOW}ℹ No TSTRUCT_TOKEN found. Using default DAGRE layout engine.${NC}" >&2
        echo "To use TALA, set TSTRUCT_TOKEN in .env or environment" >&2
    fi
    
    echo -e "${GREEN}Using layout engine: $layout_engine${NC}" >&2
    # Only return the layout engine name
    echo "$layout_engine"
}

# Generate a single D2 diagram
generate_single_diagram() {
    local d2_file="$1"
    local layout_engine="${2:-dagre}"
    
    if [ ! -f "$d2_file" ]; then
        echo -e "${RED}File not found: $d2_file${NC}"
        return 1
    fi
    
    local dir=$(dirname "$d2_file")
    local basename=$(basename "$d2_file" .d2)
    local png_file="$dir/diagrams/${basename}.png"
    
    # Create diagrams directory if needed
    mkdir -p "$dir/diagrams"
    
    echo "Processing: $d2_file"
    
    # Generate with selected layout engine
    if [ "$layout_engine" = "tala" ]; then
        if TSTRUCT_TOKEN="$TSTRUCT_TOKEN" D2_LAYOUT="$layout_engine" d2 "$d2_file" "$png_file"; then
            echo -e "${GREEN}✓ Generated: $png_file${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ TALA failed, retrying with DAGRE...${NC}"
            if D2_LAYOUT="dagre" d2 "$d2_file" "$png_file"; then
                echo -e "${GREEN}✓ Generated with DAGRE fallback: $png_file${NC}"
                return 0
            fi
        fi
    else
        if D2_LAYOUT="$layout_engine" d2 "$d2_file" "$png_file"; then
            echo -e "${GREEN}✓ Generated: $png_file${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}✗ Failed to generate $png_file${NC}"
    return 1
}

# Update README files for a directory
update_readmes() {
    local arg="${1:-.}"
    local project_root=$(find_project_root)
    
    # Handle both directory paths and --top-level flag
    if [ "$arg" = "--top-level" ]; then
        if python3 "$project_root/.github/scripts/generate-readmes.py" --top-level; then
            echo -e "${GREEN}✓ Updated top-level README${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ Failed to update top-level README${NC}"
            return 1
        fi
    else
        if python3 "$project_root/.github/scripts/generate-readmes.py" "$arg"; then
            echo -e "${GREEN}✓ Updated README for $arg${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ Failed to update README for $arg${NC}"
            return 1
        fi
    fi
}

# Check if D2 is installed
check_d2_installed() {
    if ! command -v d2 &> /dev/null; then
        echo -e "${RED}Error: D2 is not installed${NC}"
        echo "To install D2, run: ./scripts/setup-local.sh"
        return 1
    fi
    return 0
}