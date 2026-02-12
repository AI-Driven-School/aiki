#!/bin/bash
# ============================================
# claude-codex-collab Update Script
# ============================================
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/claude-codex-collab/main/update.sh | bash
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

REPO_URL="https://raw.githubusercontent.com/AI-Driven-School/claude-codex-collab/main"
LATEST_VERSION="6.1.0"

echo -e "${CYAN}"
echo "┌─────────────────────────────────────────────────────────┐"
echo "│   claude-codex-collab Update                            │"
echo "│   Latest: v${LATEST_VERSION}                                        │"
echo "└─────────────────────────────────────────────────────────┘"
echo -e "${NC}"

# Check current version
CURRENT_VERSION="unknown"
if [ -f "CLAUDE.md" ]; then
    CURRENT_VERSION=$(grep -o 'v[0-9]\+\.[0-9]\+' CLAUDE.md 2>/dev/null | head -1 || echo "unknown")
fi

echo -e "Current version: ${YELLOW}${CURRENT_VERSION}${NC}"
echo -e "Latest version:  ${GREEN}v${LATEST_VERSION}${NC}"
echo ""

# Check if CLAUDE.md exists
if [ ! -f "CLAUDE.md" ]; then
    echo -e "${RED}Error: CLAUDE.md not found${NC}"
    echo "Please run this in a directory where claude-codex-collab is installed"
    exit 1
fi

# Backup
echo "Creating backup..."
BACKUP_DIR=".claude-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp CLAUDE.md "$BACKUP_DIR/" 2>/dev/null || true
cp AGENTS.md "$BACKUP_DIR/" 2>/dev/null || true
cp -r scripts "$BACKUP_DIR/" 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} $BACKUP_DIR"

echo ""
echo "Updating..."

# Update CLAUDE.md
echo -e "  ${BLUE}→${NC} CLAUDE.md"
curl -fsSL "$REPO_URL/install-fullstack.sh" | sed -n '/^cat > CLAUDE.md/,/^EOF$/p' | sed '1d;$d' > CLAUDE.md.new

# Preserve existing custom settings (## Project-specific section onwards)
if grep -q "## プロジェクト固有\|## Project-specific" CLAUDE.md 2>/dev/null; then
    echo "" >> CLAUDE.md.new
    sed -n '/## プロジェクト固有\|## Project-specific/,$p' CLAUDE.md >> CLAUDE.md.new
fi

mv CLAUDE.md.new CLAUDE.md
echo -e "  ${GREEN}✓${NC} CLAUDE.md updated"

# Update AGENTS.md
echo -e "  ${BLUE}→${NC} AGENTS.md"
curl -fsSL "$REPO_URL/install-fullstack.sh" | sed -n '/^cat > AGENTS.md/,/^EOF$/p' | sed '1d;$d' > AGENTS.md
echo -e "  ${GREEN}✓${NC} AGENTS.md updated"

# Update delegate.sh
echo -e "  ${BLUE}→${NC} scripts/delegate.sh"
mkdir -p scripts
curl -fsSL "$REPO_URL/install-fullstack.sh" | sed -n "/^cat > scripts\/delegate.sh/,/^SCRIPT_EOF$/p" | sed '1d;$d' > scripts/delegate.sh
chmod +x scripts/delegate.sh
echo -e "  ${GREEN}✓${NC} scripts/delegate.sh updated"

# Update skills
echo -e "  ${BLUE}→${NC} .claude/skills/"
mkdir -p .claude/skills
for skill in project implement test review analyze research requirements spec api; do
    curl -fsSL "$REPO_URL/install-fullstack.sh" | sed -n "/^cat > .claude\/skills\/${skill}.md/,/^EOF$/p" | sed '1d;$d' > ".claude/skills/${skill}.md" 2>/dev/null || true
done
echo -e "  ${GREEN}✓${NC} Skills updated"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Update complete! v${LATEST_VERSION}${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}What's new in v6.1:${NC}"
echo -e "  ${BLUE}•${NC} Added sub-agent utilization rules"
echo -e "    - Task(Explore) for code exploration"
echo -e "    - Task(Plan) for planning"
echo -e "    - Parallel Task execution"
echo ""
echo -e "${CYAN}Backup:${NC}"
echo -e "  ${BLUE}${BACKUP_DIR}/${NC}"
echo ""
echo -e "Details: ${BLUE}https://github.com/AI-Driven-School/claude-codex-collab/releases${NC}"
echo ""
