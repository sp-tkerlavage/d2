#!/usr/bin/env bash

# Generate D2 diagrams with various modes
# Usage: ./scripts/generate-diagrams.sh [options] [file1.d2 file2.d2 ...]
#        ./scripts/generate-diagrams.sh --modified
#        ./scripts/generate-diagrams.sh --staged
#        ./scripts/generate-diagrams.sh --all
#        ./scripts/generate-diagrams.sh file1.d2 file2.d2

set -e

# Default mode
MODE="files"  # Can be: files, all, modified, staged

# Parse command line arguments
D2_FILES=""
SHOW_HELP=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all|-a)
            MODE="all"
            shift
            ;;
        --modified|-m)
            MODE="modified"
            shift
            ;;
        --staged|-s)
            MODE="staged"
            shift
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        *.d2)
            MODE="files"
            D2_FILES="$D2_FILES $1"
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            SHOW_HELP=true
            shift
            ;;
    esac
done

# Show help if requested or on error
if [ "$SHOW_HELP" = true ]; then
    echo "Usage: $0 [options] [file1.d2 file2.d2 ...]"
    echo ""
    echo "Generate D2 diagrams with various modes."
    echo ""
    echo "Options:"
    echo "  --all, -a         Generate all diagrams in the repository"
    echo "  --modified, -m    Generate only modified diagrams (staged and unstaged)"
    echo "  --staged, -s      Generate only staged diagrams"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Generate all diagrams (default)"
    echo "  $0 file1.d2 file2.d2        # Generate specific files"
    echo "  $0 --modified               # Generate modified files only"
    echo "  $0 --staged                 # Generate staged files only"
    echo ""
    echo "If no options or files are specified, generates all diagrams."
    exit 0
fi

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Find project root and change to it
PROJECT_ROOT=$(find_project_root)
cd "$PROJECT_ROOT"

# Load environment variables
load_env

# Check if D2 is installed
if ! check_d2_installed; then
    exit 1
fi

# Determine layout engine
LAYOUT_ENGINE=$(determine_layout_engine)
echo ""

# Wrapper for generate_single_diagram from common.sh
generate_diagram() {
    generate_single_diagram "$1" "$LAYOUT_ENGINE"
}

# Determine which files to process based on mode
case "$MODE" in
    all)
        echo -e "${GREEN}Generating all diagrams...${NC}"
        D2_FILES=$(find . -name "*.d2" -not -path "./.git/*" -not -path "./node_modules/*")
        ;;
    modified)
        echo -e "${BLUE}Finding all modified .d2 files...${NC}"
        D2_FILES=$(git diff --name-only HEAD | grep '\.d2$' || true)
        if [ -z "$D2_FILES" ]; then
            echo -e "${YELLOW}No modified .d2 files found.${NC}"
            exit 0
        fi
        FILE_COUNT=$(echo "$D2_FILES" | wc -l)
        echo -e "${GREEN}Found $FILE_COUNT modified .d2 file(s)${NC}"
        ;;
    staged)
        echo -e "${BLUE}Finding staged .d2 files...${NC}"
        D2_FILES=$(git diff --cached --name-only | grep '\.d2$' || true)
        if [ -z "$D2_FILES" ]; then
            echo -e "${YELLOW}No staged .d2 files found.${NC}"
            exit 0
        fi
        FILE_COUNT=$(echo "$D2_FILES" | wc -l)
        echo -e "${GREEN}Found $FILE_COUNT staged .d2 file(s)${NC}"
        ;;
    files)
        if [ -z "$D2_FILES" ]; then
            # No files specified, default to all
            echo -e "${GREEN}No files specified, generating all diagrams...${NC}"
            D2_FILES=$(find . -name "*.d2" -not -path "./.git/*" -not -path "./node_modules/*")
        else
            echo -e "${GREEN}Generating specified diagrams...${NC}"
        fi
        ;;
esac

echo ""

# Track statistics
TOTAL=0
SUCCESS=0
FAILED=0

# Process each file
for d2_file in $D2_FILES; do
    if [ -f "$d2_file" ]; then
        TOTAL=$((TOTAL + 1))
        if generate_diagram "$d2_file"; then
            SUCCESS=$((SUCCESS + 1))
        else
            FAILED=$((FAILED + 1))
        fi
        echo ""
    else
        echo -e "${YELLOW}Warning: File not found: $d2_file${NC}"
    fi
done

# Generate/update README files
echo -e "${GREEN}Updating README files...${NC}"
if update_readmes .; then
    echo -e "${GREEN}✓ README files updated${NC}"
else
    echo -e "${YELLOW}⚠ Failed to update some README files${NC}"
fi

# Summary
echo ""
echo "=================================="
echo -e "${GREEN}Diagram Generation Complete${NC}"
echo "Total: $TOTAL"
echo -e "Success: ${GREEN}$SUCCESS${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "Failed: ${RED}$FAILED${NC}"
else
    echo -e "Failed: $FAILED"
fi
echo "Layout Engine: $LAYOUT_ENGINE"
echo "=================================="

# Show preview commands for modified/staged modes
if [ "$MODE" = "modified" ] || [ "$MODE" = "staged" ]; then
    if [ $SUCCESS -gt 0 ]; then
        echo ""
        echo -e "${CYAN}Tip: To preview the generated diagrams:${NC}"
        for d2_file in $D2_FILES; do
            if [ -f "$d2_file" ]; then
                dir=$(dirname "$d2_file")
                basename=$(basename "$d2_file" .d2)
                png_file="$dir/diagrams/${basename}.png"
                if [ -f "$png_file" ]; then
                    echo "  open $png_file"
                fi
            fi
        done
    fi
fi

# Exit with error if any diagrams failed
if [ $FAILED -gt 0 ]; then
    exit 1
fi