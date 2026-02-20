#!/bin/bash
# ============================================
# aiki Update Script
# ============================================
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/update.sh | bash
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

REPO_URL="https://raw.githubusercontent.com/AI-Driven-School/aiki/main"
LATEST_VERSION="6.3.0"

echo -e "${CYAN}"
echo "┌─────────────────────────────────────────────────────────┐"
echo "│   aiki Update                            │"
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
    echo "Please run this in a directory where aiki is installed"
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

# Update Grok integration (v6.3+)
echo -e "  ${BLUE}→${NC} .grok/ (Grok integration)"
mkdir -p .grok
curl -fsSL "$REPO_URL/.grok/GROK.md" -o ".grok/GROK.md" 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} .grok/GROK.md updated"

# Update Grok delegation rules
echo -e "  ${BLUE}→${NC} .claude/rules/ (Grok delegation)"
mkdir -p .claude/rules
curl -fsSL "$REPO_URL/.claude/rules/grok-delegation.md" -o ".claude/rules/grok-delegation.md" 2>/dev/null || true
curl -fsSL "$REPO_URL/.claude/rules/grok-delegation_ja.md" -o ".claude/rules/grok-delegation_ja.md" 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} Grok delegation rules updated"

# Update Grok hook
echo -e "  ${BLUE}→${NC} .claude/hooks/ (Grok hook)"
mkdir -p .claude/hooks
curl -fsSL "$REPO_URL/.claude/hooks/suggest-grok.sh" -o ".claude/hooks/suggest-grok.sh" 2>/dev/null || true
chmod +x .claude/hooks/suggest-grok.sh 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} Grok hook updated"

# Update agent-router with Grok keywords
curl -fsSL "$REPO_URL/.claude/hooks/agent-router.sh" -o ".claude/hooks/agent-router.sh" 2>/dev/null || true
chmod +x .claude/hooks/agent-router.sh 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} Agent router updated (Grok keywords added)"

# Update settings.json with Grok hook
curl -fsSL "$REPO_URL/.claude/settings.json" -o ".claude/settings.json" 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} Settings updated (Grok hook registered)"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Update complete! v${LATEST_VERSION}${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}What's new in v6.3:${NC}"
echo -e "  ${BLUE}•${NC} Added Grok (xAI) as 4th AI"
echo -e "    - Real-time X/Twitter trend research"
echo -e "    - Auto-suggestion via agent-router hooks"
echo -e "    - .grok/GROK.md context + delegation rules"
echo ""
echo -e "${CYAN}Backup:${NC}"
echo -e "  ${BLUE}${BACKUP_DIR}/${NC}"
echo ""
echo -e "Details: ${BLUE}https://github.com/AI-Driven-School/aiki/releases${NC}"
echo ""
