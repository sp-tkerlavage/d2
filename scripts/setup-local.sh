#!/usr/bin/env bash

# Setup script for D2 diagram development
# Usage: ./scripts/setup-local.sh [--unattended|--ci]
#   --unattended/--ci: Run without prompts (for CI/CD environments)

set -e

# Check for unattended mode
UNATTENDED=false
for arg in "$@"; do
    case $arg in
        --unattended|--ci)
            UNATTENDED=true
            shift
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Find project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Only show wizard header in interactive mode
if [ "$UNATTENDED" = false ]; then
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}   D2 Diagram Local Setup Wizard${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
else
    echo "Running D2 setup in unattended mode..."
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to prompt for yes/no
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    # In unattended mode, always use default
    if [ "$UNATTENDED" = true ]; then
        [[ "$default" =~ ^[Yy]$ ]]
        return $?
    fi
    
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -r -p "$(echo -e "$prompt")" response
    response=${response:-$default}
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Function to prompt for input with default
prompt_input() {
    local prompt="$1"
    local default="$2"
    local response
    
    # In unattended mode, always use default
    if [ "$UNATTENDED" = true ]; then
        echo "$default"
        return
    fi
    
    if [ -n "$default" ]; then
        prompt="$prompt [$default]: "
    else
        prompt="$prompt: "
    fi
    
    read -r -p "$(echo -e "$prompt")" response
    echo "${response:-$default}"
}

# Check if D2 is installed
echo -e "${BLUE}Checking D2 installation...${NC}"
D2_NEEDS_INSTALL=false
if command_exists d2; then
    D2_VERSION=$(d2 --version 2>&1 | head -1)
    echo -e "${GREEN}✓ D2 is already installed: $D2_VERSION${NC}"
    
    # Check for TALA plugin
    TALA_PLUGIN_PATH="$HOME/.local/bin/d2plugin-tala"
    if [ ! -f "$TALA_PLUGIN_PATH" ]; then
        TALA_PLUGIN_PATH="$(which d2plugin-tala 2>/dev/null || echo '')"
    fi
    
    if [ -n "$TALA_PLUGIN_PATH" ] && [ -f "$TALA_PLUGIN_PATH" ]; then
        echo -e "${GREEN}✓ TALA plugin is installed${NC}"
    else
        echo -e "${YELLOW}⚠ TALA plugin is not installed${NC}"
    fi
else
    D2_NEEDS_INSTALL=true
    echo -e "${YELLOW}⚠ D2 is not installed${NC}"
fi

echo ""

# Handle D2 installation if needed
if [ "$D2_NEEDS_INSTALL" = true ]; then
    if [ "$UNATTENDED" = true ]; then
        # In unattended mode, always install D2
        echo "Installing D2..."
        if [ -n "$TSTRUCT_TOKEN" ]; then
            curl -fsSL https://d2lang.com/install.sh | sh -s -- --tala
        else
            curl -fsSL https://d2lang.com/install.sh | sh -s --
        fi
        echo -e "${GREEN}✓ D2 installed${NC}"
        
        # Export PATH for current session
        if [ -d "$HOME/.local/bin" ]; then
            export PATH="$HOME/.local/bin:$PATH"
        elif [ -d "/opt/d2/bin" ]; then
            export PATH="/opt/d2/bin:$PATH"
        fi
    elif prompt_yes_no "${BLUE}Would you like to install D2 now?${NC}" "y"; then
        echo -e "${BLUE}Installing D2 with TALA support...${NC}"
        curl -fsSL https://d2lang.com/install.sh | sh -s -- --tala
        
        # D2 installed successfully
        echo -e "${GREEN}✓ D2 installed successfully${NC}"
        
        # Export PATH for current session
        if [ -d "$HOME/.local/bin" ]; then
            export PATH="$HOME/.local/bin:$PATH"
        elif [ -d "/opt/d2/bin" ]; then
            export PATH="/opt/d2/bin:$PATH"
        fi
    else
        echo -e "${YELLOW}Skipping D2 installation. You can install it later from: https://d2lang.com/tour/install${NC}"
    fi
fi

# In unattended mode, skip all remaining interactive steps
if [ "$UNATTENDED" = true ]; then
    # Export PATH for GitHub Actions
    if [ -n "$GITHUB_ACTIONS" ]; then
        if [ -d "$HOME/.local/bin" ]; then
            echo "$HOME/.local/bin" >> $GITHUB_PATH
        elif [ -d "/opt/d2/bin" ]; then
            echo "/opt/d2/bin" >> $GITHUB_PATH
        fi
    fi
    
    echo -e "${GREEN}✓ Setup complete (unattended)${NC}"
    exit 0
fi

# PATH configuration - runs regardless of whether D2 was just installed
echo ""
echo -e "${BLUE}Checking PATH configuration...${NC}"

# Export PATH for current session if not already done
if [ -d "$HOME/.local/bin" ] && ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Ask if user wants to update PATH in shell profiles
if prompt_yes_no "${BLUE}Would you like to add D2 to your PATH?${NC}" "y"; then
    # Initialize variables for tracking shell reload
    NEED_SHELL_RELOAD=false
    RELOAD_SHELL_PROFILE=""
    
    # Detect which shell profiles exist
    SHELL_PROFILES=()
    CURRENT_SHELL_PROFILE=""
    
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_PROFILES+=("$HOME/.bashrc")
    fi
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_PROFILES+=("$HOME/.zshrc")
    fi
    
    # Determine which is the current shell
    # Use SHELL environment variable as primary detection
    if [[ "$SHELL" == *"zsh"* ]]; then
        CURRENT_SHELL_PROFILE="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        CURRENT_SHELL_PROFILE="$HOME/.bashrc"
    # Fallback to version detection
    elif [ -n "$ZSH_VERSION" ]; then
        CURRENT_SHELL_PROFILE="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        CURRENT_SHELL_PROFILE="$HOME/.bashrc"
    fi
    
    if [ ${#SHELL_PROFILES[@]} -eq 0 ]; then
        echo -e "${YELLOW}No shell profile files found (.bashrc or .zshrc)${NC}"
    else
        # Update all found shell profiles
        for SHELL_PROFILE in "${SHELL_PROFILES[@]}"; do
            echo -e "${BLUE}Checking $(basename $SHELL_PROFILE)...${NC}"
            
            # Check if PATH needs updating
            PATH_NEEDS_UPDATE=false
            PATH_IS_COMMENTED=false
            
            # Check if PATH entry exists and is active (not commented)
            if ! grep -E '^[[:space:]]*(export\s+)?PATH=.*\$HOME/\.local/bin' "$SHELL_PROFILE" > /dev/null 2>&1; then
                # Not found as active, check if it's commented out
                if grep -E '^\s*#.*PATH=.*\$HOME/\.local/bin' "$SHELL_PROFILE" > /dev/null 2>&1; then
                    PATH_IS_COMMENTED=true
                fi
                PATH_NEEDS_UPDATE=true
            fi
            
            # Check if MANPATH needs updating (same logic as PATH)
            MANPATH_NEEDS_UPDATE=false
            MANPATH_IS_COMMENTED=false
            
            # Check if MANPATH entry exists and is active (not commented)
            if ! grep -E '^[[:space:]]*(export\s+)?MANPATH=.*\$HOME/\.local/share/man' "$SHELL_PROFILE" > /dev/null 2>&1; then
                # Not found as active, check if it's commented out
                if grep -E '^\s*#.*MANPATH=.*\$HOME/\.local/share/man' "$SHELL_PROFILE" > /dev/null 2>&1; then
                    MANPATH_IS_COMMENTED=true
                fi
                MANPATH_NEEDS_UPDATE=true
            fi
            
            # If anything needs updating, create backup first
            if [ "$PATH_NEEDS_UPDATE" = true ] || [ "$MANPATH_NEEDS_UPDATE" = true ]; then
                BACKUP_FILE="${SHELL_PROFILE}.backup.$(date +%Y%m%d_%H%M%S)"
                cp "$SHELL_PROFILE" "$BACKUP_FILE"
                echo -e "${GREEN}  ✓ Created backup: $BACKUP_FILE${NC}"
                
                # Track if we need to add a comment header
                ADDED_HEADER=false
                
                # Add PATH if needed
                if [ "$PATH_NEEDS_UPDATE" = true ]; then
                    if [ "$PATH_IS_COMMENTED" = true ]; then
                        echo -e "${YELLOW}  ℹ PATH entry found but commented out, adding active entry${NC}"
                    fi
                    echo "" >> "$SHELL_PROFILE"
                    echo "# Added by D2 setup script on $(date +%Y-%m-%d)" >> "$SHELL_PROFILE"
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_PROFILE"
                    echo -e "${GREEN}  ✓ Added D2 to PATH${NC}"
                    ADDED_HEADER=true
                else
                    echo -e "${GREEN}  ✓ PATH already configured${NC}"
                fi
                
                # Add MANPATH if needed (identical logic to PATH)
                if [ "$MANPATH_NEEDS_UPDATE" = true ]; then
                    if [ "$MANPATH_IS_COMMENTED" = true ]; then
                        echo -e "${YELLOW}  ℹ MANPATH entry found but commented out, adding active entry${NC}"
                    fi
                    if [ "$ADDED_HEADER" != true ]; then
                        echo "" >> "$SHELL_PROFILE"
                        echo "# Added by D2 setup script on $(date +%Y-%m-%d)" >> "$SHELL_PROFILE"
                    fi
                    echo 'export MANPATH="$HOME/.local/share/man:$MANPATH"' >> "$SHELL_PROFILE"
                    echo -e "${GREEN}  ✓ Added D2 man pages to MANPATH${NC}"
                else
                    echo -e "${GREEN}  ✓ MANPATH already configured${NC}"
                fi
                
                # Track if current shell needs reload (any modification to current shell)
                if [ "$SHELL_PROFILE" = "$CURRENT_SHELL_PROFILE" ]; then
                    # If we made ANY changes to the current shell profile, need reload
                    if [ "$PATH_NEEDS_UPDATE" = true ] || [ "$MANPATH_NEEDS_UPDATE" = true ]; then
                        NEED_SHELL_RELOAD=true
                        RELOAD_SHELL_PROFILE="$SHELL_PROFILE"
                    fi
                fi
            else
                echo -e "${GREEN}  ✓ Already fully configured${NC}"
            fi
        done
    fi
else
    echo -e "${YELLOW}Skipping PATH configuration${NC}"
    echo -e "${YELLOW}Note: You'll need to add $HOME/.local/bin to your PATH manually or run this script again${NC}"
    echo -e "${YELLOW}Current session PATH has been updated, but it won't persist after closing the terminal${NC}"
fi

echo ""
echo -e "${YELLOW}Note: To use TALA layout, you'll need to:${NC}"
echo -e "  1. Set your TSTRUCT_TOKEN in .env"
echo -e "  2. Use: TSTRUCT_TOKEN=<token> D2_LAYOUT=tala d2 <file>"
echo -e "  Or just run: ./scripts/generate-diagrams.sh (handles this automatically)"

echo ""

# Check for Python
echo -e "${BLUE}Checking Python installation...${NC}"
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓ Python3 is installed: $PYTHON_VERSION${NC}"
else
    echo -e "${RED}✗ Python3 is not installed${NC}"
    echo -e "${YELLOW}Please install Python 3 to use the README generation scripts${NC}"
fi

echo ""

# Setup environment file
echo -e "${BLUE}Setting up environment configuration...${NC}"

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"

# Create .env.example if it doesn't exist
if [ ! -f "$ENV_EXAMPLE" ]; then
    cat > "$ENV_EXAMPLE" << 'EOF'
# D2 Diagram Generation Configuration
# Copy this file to .env and fill in your values

# TALA License Token (optional)
# Get your token from: https://d2lang.com/tala
# Leave empty to use the default DAGRE layout engine
TSTRUCT_TOKEN=

# Additional D2 configuration (optional)
# D2_LAYOUT=tala  # Uncomment to force TALA layout (requires TSTRUCT_TOKEN)
# D2_THEME=0     # Theme ID (0-100+)
EOF
    echo -e "${GREEN}✓ Created $ENV_EXAMPLE${NC}"
fi

# Setup .env file
if [ -f "$ENV_FILE" ]; then
    echo -e "${GREEN}✓ .env file already exists${NC}"
    
    # Check if TSTRUCT_TOKEN is set
    if grep -q "^TSTRUCT_TOKEN=.\+" "$ENV_FILE"; then
        echo -e "${GREEN}✓ TALA token is configured in .env${NC}"
    else
        if prompt_yes_no "${BLUE}Would you like to add your TALA license token now?${NC}" "n"; then
            echo -e "${YELLOW}Get your token from: https://d2lang.com/tala${NC}"
            TOKEN=$(prompt_input "${BLUE}Enter your TALA token (or press Enter to skip)${NC}" "")
            
            if [ -n "$TOKEN" ]; then
                # Update or add TSTRUCT_TOKEN in .env
                if grep -q "^TSTRUCT_TOKEN=" "$ENV_FILE"; then
                    sed -i.bak "s/^TSTRUCT_TOKEN=.*/TSTRUCT_TOKEN=$TOKEN/" "$ENV_FILE"
                    rm -f "$ENV_FILE.bak"
                else
                    echo "TSTRUCT_TOKEN=$TOKEN" >> "$ENV_FILE"
                fi
                echo -e "${GREEN}✓ TALA token saved to .env${NC}"
            fi
        fi
    fi
else
    if prompt_yes_no "${BLUE}Would you like to create a .env file?${NC}" "y"; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        echo -e "${GREEN}✓ Created .env file from template${NC}"
        
        if prompt_yes_no "${BLUE}Would you like to add your TALA license token?${NC}" "n"; then
            echo -e "${YELLOW}Get your token from: https://d2lang.com/tala${NC}"
            TOKEN=$(prompt_input "${BLUE}Enter your TALA token (or press Enter to skip)${NC}" "")
            
            if [ -n "$TOKEN" ]; then
                sed -i.bak "s/^TSTRUCT_TOKEN=$/TSTRUCT_TOKEN=$TOKEN/" "$ENV_FILE"
                rm -f "$ENV_FILE.bak"
                echo -e "${GREEN}✓ TALA token saved to .env${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}Skipping .env creation. You can create it later from $ENV_EXAMPLE${NC}"
    fi
fi

echo ""

# Setup Git hooks
echo -e "${BLUE}Setting up Git hooks...${NC}"

CURRENT_HOOKS_PATH=$(git config --get core.hooksPath || echo "")

if [ "$CURRENT_HOOKS_PATH" = ".githooks" ]; then
    echo -e "${GREEN}✓ Git hooks are already configured to use .githooks${NC}"
else
    echo -e "${YELLOW}Current Git hooks path: ${CURRENT_HOOKS_PATH:-default (.git/hooks)}${NC}"
    echo ""
    echo -e "${CYAN}The pre-commit hook will:${NC}"
    echo "  • Automatically generate PNG diagrams when you commit .d2 files"
    echo "  • Update README files to include the new diagrams"
    echo "  • Stage the generated files with your commit"
    echo "  • Use your personal TALA token if configured"
    echo ""
    
    if prompt_yes_no "${BLUE}Would you like to enable the pre-commit hook for automatic diagram generation?${NC}" "y"; then
        git config core.hooksPath .githooks
        echo -e "${GREEN}✓ Git hooks configured to use .githooks${NC}"
        echo -e "${YELLOW}Note: You can disable this anytime with: git config --unset core.hooksPath${NC}"
    else
        echo -e "${YELLOW}Skipping Git hooks setup${NC}"
        echo -e "${YELLOW}You can enable it later with: git config core.hooksPath .githooks${NC}"
    fi
fi

echo ""

# Test the setup
echo -e "${BLUE}Testing the setup...${NC}"

# Create a test D2 file
TEST_FILE="/tmp/test-d2-setup.d2"
cat > "$TEST_FILE" << 'EOF'
test: "Setup Test" {
  shape: rectangle
}
EOF

echo -e "${BLUE}Running test diagram generation...${NC}"

# Source the .env file if it exists
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# Try to generate a test diagram
if command_exists d2; then
    LAYOUT_ENGINE="dagre"
    
    if [ -n "$TSTRUCT_TOKEN" ]; then
        # Try TALA
        if TSTRUCT_TOKEN="$TSTRUCT_TOKEN" D2_LAYOUT=tala d2 "$TEST_FILE" /tmp/test-output.png 2>/dev/null; then
            echo -e "${GREEN}✓ TALA layout engine is working${NC}"
            LAYOUT_ENGINE="tala"
        else
            echo -e "${YELLOW}⚠ TALA test failed, falling back to DAGRE${NC}"
        fi
    fi
    
    if [ "$LAYOUT_ENGINE" = "dagre" ]; then
        if D2_LAYOUT=dagre d2 "$TEST_FILE" /tmp/test-output.png 2>/dev/null; then
            echo -e "${GREEN}✓ DAGRE layout engine is working${NC}"
        else
            echo -e "${RED}✗ D2 test failed${NC}"
        fi
    fi
    
    # Clean up test files
    rm -f "$TEST_FILE" /tmp/test-output.png
else
    echo -e "${YELLOW}⚠ Skipping test (D2 not installed)${NC}"
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${GREEN}You can now:${NC}"
echo ""
echo "1. Generate diagrams manually:"
echo -e "   ${CYAN}./scripts/generate-diagrams.sh [file.d2]${NC}"
echo ""
echo "2. Generate all diagrams:"
echo -e "   ${CYAN}./scripts/generate-diagrams.sh${NC}"
echo ""

if [ "$CURRENT_HOOKS_PATH" = ".githooks" ] || [ -n "$(git config --get core.hooksPath | grep '.githooks')" ]; then
    echo "3. Diagrams will be auto-generated when you commit .d2 files"
else
    echo "3. Enable auto-generation on commit:"
    echo -e "   ${CYAN}git config core.hooksPath .githooks${NC}"
fi

echo ""

if [ ! -f "$ENV_FILE" ] || ! grep -q "^TSTRUCT_TOKEN=.\+" "$ENV_FILE" 2>/dev/null; then
    echo -e "${YELLOW}Tip: Add your TALA token to .env for premium layouts${NC}"
fi

echo ""
echo -e "${GREEN}Happy diagramming! 🎨${NC}"

# Show shell reload message at the very end if needed
if [ "$NEED_SHELL_RELOAD" = true ]; then
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠ IMPORTANT: To use D2 in your current shell, run:${NC}"
    echo -e "${CYAN}  source $RELOAD_SHELL_PROFILE${NC}"
    echo -e "${YELLOW}Or open a new terminal window${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi