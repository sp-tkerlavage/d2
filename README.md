# D2 Diagrams Repository

## Sections

- [Data Engineering](./data-engineering/)

Welcome to our `data-diagrams` repository! This is a centralized location for all architectural and technical diagrams across our data groups.

## Table of Contents
- [About D2](#about-d2)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Working with Diagrams](#working-with-diagrams)
- [CI/CD Pipeline](#cicd-pipeline)
- [TALA License Management](#tala-license-management)
- [Pre-commit Hook](#pre-commit-hook)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Contributing](#contributing)

## About D2

D2 is a modern diagram scripting language that turns text to diagrams. It's designed to be easy to write and maintain, making it perfect for version-controlled technical documentation.

**Key Features:**
- **Text-based**: Easy to review in pull requests
- **Deterministic**: Same input always produces the same output
- **Powerful**: Supports complex layouts, styling, and animations
- **TALA Layout**: Optional premium layout engine for superior diagram layouts

**Resources:**
- [D2 Documentation](https://d2lang.com)
- [D2 Playground](https://play.d2lang.com)
- [D2 Examples](https://github.com/terrastruct/d2/tree/master/docs/examples)

## Quick Start

### Initial Setup

Run the interactive setup wizard (one-time):
```bash
# This will install D2, configure TALA (optional), and set up git hooks (optional)
./scripts/setup-local.sh
```

Or manually:
```bash
# Install D2 with TALA support
curl -fsSL https://d2lang.com/install.sh | sh -s -- --tala

# Configure TALA token (optional)
cp .env.example .env
# Edit .env and add: TSTRUCT_TOKEN=your_token_here

# Enable pre-commit hook (optional)
git config core.hooksPath .githooks
```

### Testing Your Setup

```bash
# Quick test
echo 'test: "Hello"' > test.d2
./scripts/generate-diagrams.sh test.d2
ls -la diagrams/test.png
rm -rf test.d2 diagrams/
```

## Repository Structure

```
domain-area/
├── subdomain/
│   ├── 00-subdomain.md          # Optional directory-level docs
│   ├── 01-diagram-name.d2       # Diagram source
│   ├── 01-diagram-name.md       # Optional companion documentation
│   ├── diagrams/                # Auto-generated PNG images
│   │   └── 01-diagram-name.png
│   └── README.md                # Auto-generated index
```

### Naming Conventions

- **Diagrams**: `XX-descriptive-name.d2` where XX is a two-digit number (e.g., `01-architecture.d2`)
- **Companion docs**: Same name with `.md` extension (e.g., `01-architecture.md`)
- **Directory docs**: `00-{directory-name}.md` or `{directory-name}.md`
- Use **kebab-case** for all file names (lowercase with hyphens)

## Working with Diagrams

### Development Workflow

#### 1. Interactive Development (Recommended)
```bash
# Use D2's watch mode for live preview
d2 --watch path/to/diagram.d2

# This opens a browser that auto-refreshes when you save changes
```

#### 2. Using the `generate-diagrams` Helper Script 
```bash
# Generate specific diagrams
./scripts/generate-diagrams.sh path/to/diagram.d2

# Generate all diagrams
./scripts/generate-diagrams.sh --all

# Generate only modified diagrams (staged and unstaged)
./scripts/generate-diagrams.sh --modified

# Generate only staged diagrams
./scripts/generate-diagrams.sh --staged

# Generate files changed in last commit
git diff --name-only HEAD~1 HEAD | grep '\.d2$' | xargs ./scripts/generate-diagrams.sh

# Generate all diagrams in a directory
find my-domain -name "*.d2" -exec ./scripts/generate-diagrams.sh {} \;

# See all options
./scripts/generate-diagrams.sh --help
```

### Manual Generation

```bash
# Basic generation
d2 input.d2 output.png

# With TALA layout
TSTRUCT_TOKEN=<token> D2_LAYOUT=tala d2 input.d2 output.png

# Format/validate syntax
d2 fmt diagram.d2
```

## Pre-commit Hook

The optional pre-commit hook automatically generates diagrams when you commit `.d2` files.

### Behavior

When enabled, the hook will:
1. Detect staged `.d2` files
2. Generate PNG diagrams
3. Update affected README files
4. Include everything in your commit

**Notes:**
- Uses your personal TALA token if configured -- Falls back to DAGRE if TALA unavailable

### Enable/Disable pre-commit hook

```bash
# Enable
git config core.hooksPath .githooks

# Disable
git config --unset core.hooksPath

# Check status
git config --get core.hooksPath
```

### Bypass pre-commit hook

```bash
# Skip the hook for one commit
git commit --no-verify
```

## CI/CD Pipeline

The GitHub Actions workflow automatically runs on pull requests to the `stage` branch.

### How It Works

1. **Selective Generation**: Only generates diagrams for `.d2` files without corresponding PNG changes. Generates/modifies readmes related to modified .md files
3. **Auto-commit**: Commits generated diagrams back to the PR

### Workflow Behavior

| Scenario | Action |
|----------|--------|
| `.d2` file changed, PNG not changed | Generate diagram, update README |
| `.d2` and PNG both changed | Skip generation, update README only |
| Companion `.md` file changed | Update README only |
| New `.d2` file added | Generate diagram, update README |

## TALA License Management

### For CI/CD

Set the `TALA_API_KEY` repository secret:
1. Go to Settings → Secrets and variables → Actions
2. Add new repository secret named `TALA_API_KEY`
3. Paste your TALA license token

### For Local Development

Choose one method:

#### Option 1: .env file (Recommended)
```bash
# Copy template and add your token
cp .env.example .env
# Edit .env: TSTRUCT_TOKEN=your_token_here
```

#### Option 2: Environment variable
```bash
export TSTRUCT_TOKEN=your_token_here
./scripts/generate-diagrams.sh
```

## Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| **D2 command not found** | Run `./scripts/setup-local.sh` or install manually |
| **TALA not working** | Ensure token in `.env` is valid |
| **Pre-commit hook not running** | Run `git config core.hooksPath .githooks` to enable pre-commit hook|
| **PNG not generating** | Check syntax with `d2 fmt file.d2` |
| **CI skipping generation** | Check if both `.d2` and `.png` were committed |
| **README not updating** | Run `python3 .github/scripts/generate-readmes.py` |


## Best Practices

### Diagram Design
- **Focus**: One concept per diagram
- **Naming**: Use descriptive, action-oriented names
- **Size**: Keep diagrams readable (avoid overcrowding)
- **Consistency**: Use common styling across related diagrams

### Documentation
- **Companion Files**: Add `.md` files for complex diagrams
- **Context**: Explain the "why" not just the "what"
- **Decisions**: Document architectural choices
- **Assumptions**: Note constraints and dependencies

### Workflow
- **Local First**: Test diagrams locally before committing
- **Security**: Never commit TALA tokens

### Development Tips
- Use watch mode (`d2 --watch`) for rapid iteration
- (Optional) Use ./scripts/generate-diagrams.sh to preview pngs with `--modified` flag during active development, or`--staged` before committing
- Keep companion docs concise but comprehensive

## Contributing

1. **Create a feature branch** from `stage`
   ```bash
   git checkout stage
   git pull origin stage
   git checkout -b feature/your-diagram-name
   ```

2. **Add or modify your diagrams**
   - Follow naming conventions
   - Include companion documentation if needed
   - (Optional) Test locally with `./scripts/generate-diagrams.sh`

3. **Create a pull request** to `stage`
   - CI/CD will automatically generate PNGs if not included in your commit
   - READMEs will be updated
   - Review generated images in the PR

4. **After approval**, merge to `stage`
   - Changes will be included in next release to `main`
