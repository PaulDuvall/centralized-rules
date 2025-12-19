# Agent Skills Implementation Plan (Option 2)

**Goal:** Full Agent Skills compliance while preserving all advanced features

**Version:** 2.0.0 (breaking changes)

**Total Tasks:** 27 beads tasks

---

## Phase 1: Research & Planning (1 task)

### as1: Research Agent Skills specification and best practices
- Deep dive into agentskills.io specification
- Understand required vs optional fields
- Study tool compatibility matrix
- Review example skills from community
- **Deliverable:** docs/agent-skills-research.md

---

## Phase 2: Core Structure (5 tasks)

### as2: Create comprehensive skill.json manifest
- Define all required fields (name, version, description, etc.)
- Configure instructions entry point
- List capabilities and compatible tools
- **File:** skill.json at repository root

### as7: Create instructions/README.md entry point
- Overview of progressive disclosure system
- Discovery instructions for AI agents
- Quick start examples
- Tool-specific integration notes
- **Audience:** Both AI and human developers

### as8: Update index.json for instructions/ paths
- Update all file paths to instructions/
- Add agentSkillsVersion field
- Add tier1/tier2 hook references
- **File:** instructions/index.json

### as10: Create resources/ directory for templates and examples
- examples/ (project examples)
- templates/ (contribution templates)
- schemas/ (JSON schemas for validation)

### as26: Update .gitignore for new structure
- Add generated tool-specific files (.cursor/, .vscode/, etc.)
- Add npm artifacts
- Ensure .claude/AGENTS.md is ignored

---

## Phase 3: Directory Restructure (5 tasks)

### as3: Reorganize base/ → instructions/base/
- Move 23 base rule files
- Update all references in documentation
- Update script paths
- **Breaking change**

### as4: Reorganize languages/ → instructions/languages/
- Move 7 language directories
- Update language detection in scripts
- Update skill-rules.json mappings

### as5: Reorganize frameworks/ → instructions/frameworks/
- Move 7 framework directories
- Update framework detection
- Test multi-framework projects

### as6: Reorganize cloud/ → instructions/cloud/
- Move cloud provider rules (AWS, Vercel)
- Update cloud detection logic

### as9: Reorganize .claude/ → scripts/
- Move activate-rules.sh → scripts/hooks/
- Move skill-rules.json → scripts/skills/
- Keep generated files in .claude/
- **Rationale:** Separate source from generated output

---

## Phase 4: Script Updates (2 tasks)

### as11: Update install-hooks.sh for new structure
- Update source paths to scripts/
- Add skill.json validation
- Update installation messages
- Test fresh install (global and local)

### as12: Update sync-ai-rules.sh for instructions/ directory
- Update all REPO_BASE_URL paths
- Update generated .claude/rules/ paths
- Add skill.json awareness
- Test with Python+FastAPI and TypeScript+React

---

## Phase 5: Multi-Tool Support (3 tasks)

### as13: Add multi-tool installer script
- Auto-detect installed tools (Claude Code, Cursor, VS Code)
- Tool-specific installation logic
- Interactive mode with --all flag
- **File:** install-agent-skill.sh

### as14: Add Cursor-specific integration
- Generate .cursorrules
- Create .cursor/skill.json
- Symlink to instructions/
- Test in Cursor IDE

### as15: Add VS Code Claude extension integration
- Create .vscode/claude-skill.json
- Configure instructionsPath
- Test with VS Code Claude extension

---

## Phase 6: Documentation (5 tasks)

### as16: Update README.md for Agent Skills
- Mention Agent Skills compliance in hero
- Show multi-tool installation
- Update "How It Works" section
- Add tool support matrix
- Fix all code examples with new paths

### as17: Update ARCHITECTURE.md with Agent Skills structure
- Document new directory structure
- Update data flow diagrams
- Add Agent Skills Integration section
- Explain cross-tool compatibility

### as18: Create CHANGELOG.md for v2.0.0
- Document breaking changes
- List all path changes (old → new)
- Migration guide summary
- Emphasize preserved features

### as19: Create migration guide for v1 to v2
- Path mapping table
- Step-by-step migration
- Custom integration updates
- Rollback instructions
- **Note:** Simple since no existing users

### as20: Update all internal file cross-references
- Scan all .md files for old paths
- Update PRACTICE_CROSSREFERENCE.md
- Update ANTI_PATTERNS.md
- Fix all internal links

---

## Phase 7: Quality Assurance (2 tasks)

### as21: Create validation script for Agent Skills compliance
- Validate skill.json structure
- Check instructions/ directory
- Verify no broken links
- Check for old paths at root
- **File:** scripts/validate-agent-skills.sh
- **CI:** Add to GitHub Actions

### as27: Final review and cleanup before v2.0.0 release
- Complete checklist (code, docs, testing, metadata)
- All tests passing
- Tag v2.0.0
- Push to GitHub

---

## Phase 8: Testing (2 tasks)

### as22: Test end-to-end with Claude Code CLI
- Fresh installation
- Hook activation and visual feedback
- Progressive disclosure validation
- Token efficiency measurement
- Multi-language project testing

### as23: Test integration with Cursor
- Install in Cursor
- Verify rule discovery
- Test code generation follows standards
- Document Cursor-specific behavior

---

## Phase 9: Publishing (Future - 2 tasks)

### as24: Create npm package preparation
- Create package.json
- Configure bin scripts
- Add .npmignore
- Test npm pack
- **Note:** Don't publish yet

### as25: Add to agentskills.io directory
- Submit to Agent Skills catalog
- Provide metadata
- Link GitHub and npm
- **Prerequisite:** v2.0.0 released

---

## Summary

**Breaking Changes:**
- 📁 `base/` → `instructions/base/`
- 📁 `languages/` → `instructions/languages/`
- 📁 `frameworks/` → `instructions/frameworks/`
- 📁 `cloud/` → `instructions/cloud/`
- 📁 `.claude/hooks/` → `scripts/hooks/`
- 📁 `.claude/skills/` → `scripts/skills/`

**Preserved Features (All Intact):**
- ✅ Two-tier architecture (bash hook + TypeScript skill)
- ✅ Progressive disclosure with relevance scoring
- ✅ Token budgets (500-5500 tokens)
- ✅ Caching (1-hour TTL)
- ✅ Visual feedback system
- ✅ Smart detection (languages/frameworks/keywords)

**New Capabilities:**
- ✅ Agent Skills compliant
- ✅ Cross-tool support (Cursor, VS Code, etc.)
- ✅ Standard manifest (skill.json)
- ✅ NPM package ready
- ✅ Community discoverable

**Estimated Timeline:**
- Phase 1-2 (Research + Core): 1-2 days
- Phase 3 (Restructure): 1 day
- Phase 4 (Scripts): 1 day
- Phase 5 (Multi-tool): 1-2 days
- Phase 6 (Docs): 1-2 days
- Phase 7 (QA): 1 day
- Phase 8 (Testing): 1 day
- **Total: 7-10 days**

Phase 9 (Publishing) is future work after initial release.

---

## Task Dependencies

```
as1 (Research)
  ↓
as2,as7,as8,as10 (Core Structure)
  ↓
as3,as4,as5,as6,as9 (Restructure) ← Must be done together
  ↓
as11,as12 (Script Updates) ← Depends on restructure
  ↓
as13,as14,as15 (Multi-tool) ← Depends on scripts
  ↓
as16,as17,as18,as19,as20 (Docs) ← Can start earlier
  ↓
as21 (Validation) ← Depends on everything
  ↓
as22,as23 (Testing) ← Final validation
  ↓
as27 (Final Review) ← Release checklist
  ↓
as24,as25 (Publishing) ← Post-release
```

---

## How to Track Progress

All 27 tasks are now in `.beads/issues.jsonl` with status "open".

**Filter Agent Skills tasks:**
```bash
# View all Agent Skills tasks
grep "AGENT SKILLS" .beads/issues.jsonl | jq -r '.title'

# Count remaining tasks
grep "AGENT SKILLS" .beads/issues.jsonl | jq -r 'select(.status=="open")' | wc -l

# View by phase
grep "Phase: Research" .beads/issues.jsonl | jq -r '.title'
```

**Task Naming Convention:**
- All tasks prefixed with "AGENT SKILLS:"
- IDs: `centralized-rules-as1` through `centralized-rules-as27`
- Priorities: 1 (critical), 2 (important), 3 (nice-to-have)

---

## Success Criteria

✅ **Agent Skills Compliant:**
- Valid skill.json at root
- instructions/ directory structure
- Cross-tool compatibility

✅ **Backwards Compatible Features:**
- All advanced features preserved
- Progressive disclosure works
- Two-tier architecture intact

✅ **Multi-Tool Support:**
- Works with Claude Code (full features)
- Works with Cursor (rules directory)
- Works with VS Code Claude extension
- Generates Copilot instructions

✅ **Quality:**
- All tests passing
- No broken links
- Documentation complete
- Validation script passes

✅ **Community Ready:**
- Published to GitHub
- NPM package prepared
- Listed on agentskills.io
