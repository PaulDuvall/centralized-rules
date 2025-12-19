# AGENT SKILLS: Research Agent Skills specification and best practices

**Phase: Research & Planning**

Deep dive into Agent Skills specification from agentskills.io to understand:
1. Required fields in skill.json manifest
2. Standard directory structure conventions
3. Instructions directory organization patterns
4. How skills are discovered by different tools (Cursor, VS Code, Claude Code)
5. Examples of successful agent skills in the wild
6. Versioning and update mechanisms
7. Publishing to npm and agent skills directory

**Deliverables:**
- Document findings in docs/agent-skills-research.md
- List of required vs optional skill.json fields
- Directory structure template
- Tool compatibility matrix

**Resources:**
- https://agentskills.io/
- GitHub: anthropics/agent-skills repository
- Example skills from community

---

# AGENT SKILLS: Create comprehensive skill.json manifest

**Phase: Core Structure**

Create the Agent Skills manifest file with all metadata:

**Required fields:**
- name: "centralized-rules"
- version: "2.0.0" (major version for Agent Skills compliance)
- description: Progressive disclosure coding standards
- author, homepage, license

**Instructions configuration:**
- entry: "instructions/README.md"
- mode: "progressive"
- tier1/tier2 configuration for two-tier architecture

**Capabilities:**
- List all coding standards categories
- Language/framework support
- Detection capabilities

**Compatible tools:**
- claude-code (full features)
- cursor (rules directory)
- vscode-claude, github-copilot

**File location:** skill.json at repository root

**Testing:** Validate JSON schema, test with skill discovery tools

---

# AGENT SKILLS: Reorganize base/ → instructions/base/

**Phase: Directory Restructure**

Move all base rules from root to instructions/ subdirectory:

**Actions:**
```bash
mkdir -p instructions
git mv base/ instructions/base/
```

**Update references in:**
- README.md (all base/ paths → instructions/base/)
- ARCHITECTURE.md
- sync-ai-rules.sh
- .claude/hooks/activate-rules.sh
- skill-rules.json
- All cross-references in rule files

**Files affected:** 23 base rule files

**Testing:**
- Verify no broken links
- Test sync script still works
- Validate hook still activates
- Check index.json generation

**Note:** This is a breaking change - document in CHANGELOG

---

# AGENT SKILLS: Reorganize languages/ → instructions/languages/

**Phase: Directory Restructure**

Move all language rules to instructions/ subdirectory:

**Actions:**
```bash
git mv languages/ instructions/languages/
```

**Update references in:**
- README.md
- ARCHITECTURE.md
- sync-ai-rules.sh (language detection paths)
- skill-rules.json (language rule mappings)
- PRACTICE_CROSSREFERENCE.md

**Languages affected:**
- python/ (2 files)
- typescript/ (2 files)
- javascript/ (2 files)
- go/ (2 files)
- rust/ (2 files)
- java/ (2 files)
- csharp/ (2 files)

**Testing:** Verify language detection and rule loading still works

---

# AGENT SKILLS: Reorganize frameworks/ → instructions/frameworks/

**Phase: Directory Restructure**

Move all framework rules to instructions/ subdirectory:

**Actions:**
```bash
git mv frameworks/ instructions/frameworks/
```

**Update references in:**
- README.md
- ARCHITECTURE.md
- sync-ai-rules.sh (framework detection)
- skill-rules.json (framework mappings)

**Frameworks affected:**
- react/
- django/
- fastapi/
- express/
- springboot/
- nextjs/
- nestjs/

**Testing:** Verify framework detection works for multi-framework projects

---

# AGENT SKILLS: Reorganize cloud/ → instructions/cloud/

**Phase: Directory Restructure**

Move all cloud provider rules to instructions/ subdirectory:

**Actions:**
```bash
git mv cloud/ instructions/cloud/
```

**Update references in:**
- README.md
- ARCHITECTURE.md
- sync-ai-rules.sh (cloud detection)

**Cloud providers affected:**
- aws/ (2 files)
- vercel/ (6 files)
- azure/ (planned)
- gcp/ (planned)

**Testing:** Verify Vercel and AWS detection works

---

# AGENT SKILLS: Create instructions/README.md entry point

**Phase: Core Structure**

Create the main entry point for agent skills discovery:

**File:** instructions/README.md

**Content:**
1. Overview of progressive disclosure system
2. How to discover and load rules
3. Rule organization (4 dimensions)
4. Quick start examples
5. Link to index.json for machine-readable catalog
6. Token efficiency guidance
7. Tool-specific integration notes

**Audience:** Both AI agents and human developers

**Style:** Similar to current .claude/AGENTS.md but more generic (not Claude-specific)

**Testing:** Verify AI agents can understand and follow discovery instructions

---

# AGENT SKILLS: Update index.json for instructions/ paths

**Phase: Core Structure**

Update the machine-readable rule index with new paths:

**Changes:**
- All rule file paths: base/ → instructions/base/
- All rule file paths: languages/ → instructions/languages/
- All rule file paths: frameworks/ → instructions/frameworks/
- All rule file paths: cloud/ → instructions/cloud/

**Add new fields:**
- agentSkillsVersion: "1.0"
- entryPoint: "instructions/README.md"
- tier1Hook: "scripts/hooks/activate-rules.sh"
- tier2Skill: "scripts/skills/before-response.ts"

**File location:** instructions/index.json

**Testing:** Validate JSON schema, test programmatic parsing

---

# AGENT SKILLS: Reorganize .claude/ → scripts/

**Phase: Directory Restructure**

Move automation scripts to centralized scripts/ directory:

**Actions:**
```bash
mkdir -p scripts/hooks scripts/skills
git mv .claude/hooks/activate-rules.sh scripts/hooks/
git mv .claude/skills/skill-rules.json scripts/skills/
git mv .claude/skills/before-response.ts scripts/skills/ # if exists
```

**Keep in .claude/:** (these are generated/tool-specific)
- .claude/AGENTS.md (generated)
- .claude/RULES.md (generated)
- .claude/rules/ (generated)
- .claude/settings.json (user-specific)

**Update paths in:**
- install-hooks.sh
- skill.json manifest
- README.md installation instructions

**Rationale:** Separate source automation (scripts/) from generated output (.claude/)

---

# AGENT SKILLS: Create resources/ directory for templates and examples

**Phase: Core Structure**

Create resources/ directory following Agent Skills conventions:

**Structure:**
```
resources/
├── examples/
│   ├── python-fastapi-project.md
│   ├── typescript-react-project.md
│   └── go-project.md
├── templates/
│   ├── new-language-template.md
│   ├── new-framework-template.md
│   └── custom-rule-template.md
└── schemas/
    ├── skill-manifest.schema.json
    └── rule-frontmatter.schema.json
```

**Content:**
- Move examples/USAGE_EXAMPLES.md → resources/examples/
- Create templates for contributing new rules
- JSON schemas for validation

**Benefits:** Standard location for supplementary materials

---

# AGENT SKILLS: Update install-hooks.sh for new structure

**Phase: Script Updates**

Update installation script to work with Agent Skills structure:

**Changes:**
1. Update source paths:
   - Old: $RULES_REPO_PATH/.claude/hooks/
   - New: $RULES_REPO_PATH/scripts/hooks/

2. Update skill rules path:
   - Old: $RULES_REPO_PATH/.claude/skills/
   - New: $RULES_REPO_PATH/scripts/skills/

3. Update installation messages to mention Agent Skills

4. Add validation that skill.json exists

5. Update test to verify hook works with new paths

**Testing:**
- Fresh install (local and global)
- Verify hook activation
- Test with sample project

**Backwards compatibility:** None needed (breaking change)

---

# AGENT SKILLS: Update sync-ai-rules.sh for instructions/ directory

**Phase: Script Updates**

Update sync script to use instructions/ directory:

**Changes:**
1. Update REPO_BASE_URL paths:
   - base/ → instructions/base/
   - languages/ → instructions/languages/
   - frameworks/ → instructions/frameworks/
   - cloud/ → instructions/cloud/

2. Update generated .claude/rules/ to use instructions/

3. Update AGENTS.md generation to reference instructions/

4. Update index.json generation

5. Add skill.json awareness (read version, capabilities)

**Testing:**
- Test with Python+FastAPI project
- Test with TypeScript+React project
- Verify all detection still works
- Check generated files have correct paths

---

# AGENT SKILLS: Add multi-tool installer script

**Phase: Multi-Tool Support**

Create install-agent-skill.sh that detects and installs for multiple tools:

**Features:**
1. Auto-detect installed tools:
   - claude-code (check ~/.claude/ or command)
   - cursor (check ~/.cursor/ or command)
   - vscode (check code command)
   - Detect from project files

2. Tool-specific installation:
   - Claude Code: Full two-tier system (current)
   - Cursor: Copy skill.json + symlink instructions/
   - VS Code: Create .vscode/claude-instructions.json
   - Copilot: Generate .github/copilot-instructions.md

3. Interactive mode:
   - Ask which tools to install for
   - Allow --all flag

4. Validation after install

**File:** install-agent-skill.sh (new, alongside install-hooks.sh)

**Testing:** Test with each tool individually and combined

---

# AGENT SKILLS: Add Cursor-specific integration

**Phase: Multi-Tool Support**

Create Cursor integration following Agent Skills:

**Actions:**
1. Generate .cursorrules pointing to instructions/
2. Create .cursor/skill.json (copy of root skill.json)
3. Symlink .cursor/instructions → ../instructions/
4. Add Cursor-specific documentation

**Script:** Add generate_cursor_integration() to install script

**Content:**
```
# .cursorrules
Agent Skill: centralized-rules
See instructions/ directory for progressive coding standards.
Entry: instructions/README.md
```

**Testing:** Test in Cursor IDE, verify rules are discovered

---

# AGENT SKILLS: Add VS Code Claude extension integration

**Phase: Multi-Tool Support**

Create VS Code integration for Claude extension:

**Actions:**
1. Create .vscode/claude-skill.json:
   ```json
   {
     "skill": "centralized-rules",
     "instructionsPath": "./instructions",
     "entryPoint": "README.md",
     "progressive": true
   }
   ```

2. Add to install-agent-skill.sh

3. Document VS Code setup in README

**Testing:** Test with VS Code Claude extension

---

# AGENT SKILLS: Update README.md for Agent Skills

**Phase: Documentation**

Rewrite README.md to reflect Agent Skills approach:

**Major changes:**
1. **Hero section:** Mention Agent Skills compliance
2. **Quick Start:** Show multi-tool installation
3. **How It Works:** Explain Agent Skills + two-tier architecture
4. **Installation:** New install-agent-skill.sh instructions
5. **Tool Support:** Matrix of Claude Code/Cursor/VS Code/Copilot
6. **Rule Architecture:** Update paths to instructions/
7. **Add section:** Publishing and Sharing as Agent Skill

**New sections:**
- Agent Skills Compatibility
- Cross-Tool Usage
- NPM Package Installation (future)

**Update all code examples with new paths**

**Testing:** Verify all links work, run through installation on fresh project

---

# AGENT SKILLS: Update ARCHITECTURE.md with Agent Skills structure

**Phase: Documentation**

Update architecture documentation:

**Sections to update:**
1. **Directory Structure:** Show new instructions/ organization
2. **Data Flow:** Update with scripts/ paths
3. **Components:** Document skill.json role
4. **Agent Skills Integration:** New section explaining compliance
5. **Cross-Tool Compatibility:** How different tools use the skill
6. **Progressive Disclosure:** Still works, just different structure

**Add diagrams:**
- Agent Skills structure
- Multi-tool integration flow
- Discovery process for different tools

**Testing:** Technical review for accuracy

---

# AGENT SKILLS: Create CHANGELOG.md for v2.0.0

**Phase: Documentation**

Document the breaking changes in Agent Skills migration

---

# AGENT SKILLS: Create migration guide for v1 to v2

**Phase: Documentation**

Create migration guide for existing users

---

# AGENT SKILLS: Update all internal file cross-references

**Phase: Cleanup**

Update all markdown files that reference old paths

---

# AGENT SKILLS: Create validation script for Agent Skills compliance

**Phase: Quality Assurance**

Create scripts/validate-agent-skills.sh to validate structure

---

# AGENT SKILLS: Test end-to-end with Claude Code CLI

**Phase: Testing**

Comprehensive testing with Claude Code

---

# AGENT SKILLS: Test integration with Cursor

**Phase: Testing**

Test Agent Skills work with Cursor

---

# AGENT SKILLS: Create npm package preparation

**Phase: Publishing (Future)**

Prepare package.json for npm publishing

---

# AGENT SKILLS: Add to agentskills.io directory (future)

**Phase: Publishing (Future)**

Submit to Agent Skills catalog

---

# AGENT SKILLS: Update .gitignore for new structure

**Phase: Cleanup**

Update .gitignore to reflect Agent Skills structure

---

# AGENT SKILLS: Final review and cleanup before v2.0.0 release

**Phase: Release Preparation**

Final checklist before releasing v2.0.0
