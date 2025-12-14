#!/usr/bin/env python3
"""
Rules Parser Module
Parses AGENTS.md and rules index to generate selection reports
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Set
from dataclasses import dataclass, asdict


@dataclass
class RuleMetadata:
    """Metadata for a single rule"""
    name: str
    path: str
    category: str  # base, language, framework, cloud
    language: Optional[str] = None
    framework: Optional[str] = None
    cloud_provider: Optional[str] = None
    topics: List[str] = None
    maturity: List[str] = None
    estimated_tokens: int = 0

    def __post_init__(self):
        if self.topics is None:
            self.topics = []
        if self.maturity is None:
            self.maturity = ["mvp", "pre-production", "production"]


class RulesParser:
    """Parse and analyze rules from repository"""

    def __init__(self, repo_root: Path):
        self.repo_root = Path(repo_root)
        self.rules_dir = self.repo_root / ".claude" / "rules"
        self.index_path = self.rules_dir / "index.json"
        self.agents_path = self.repo_root / "AGENTS.md"

    def parse_index(self) -> Dict[str, List[RuleMetadata]]:
        """Parse rules from index.json"""
        if not self.index_path.exists():
            return {"base": [], "language": [], "framework": [], "cloud": []}

        with open(self.index_path) as f:
            index = json.load(f)

        parsed_rules = {
            "base": [],
            "language": [],
            "framework": [],
            "cloud": []
        }

        # Parse base rules
        for rule in index.get("rules", {}).get("base", []):
            # Use "file" key if "path" doesn't exist (for compatibility)
            rule_path = rule.get("path") or rule.get("file", "")
            parsed_rules["base"].append(RuleMetadata(
                name=rule["name"],
                path=rule_path,
                category="base",
                topics=self._extract_topics_from_path(rule_path),
                estimated_tokens=rule.get("estimatedTokens", 800)
            ))

        # Parse language rules
        for lang, rules in index.get("rules", {}).get("languages", {}).items():
            for rule in rules:
                rule_path = rule.get("path") or rule.get("file", "")
                parsed_rules["language"].append(RuleMetadata(
                    name=rule["name"],
                    path=rule_path,
                    category="language",
                    language=lang,
                    topics=self._extract_topics_from_path(rule_path),
                    estimated_tokens=rule.get("estimatedTokens", 1000)
                ))

        # Parse framework rules
        for framework, rules in index.get("rules", {}).get("frameworks", {}).items():
            for rule in rules:
                rule_path = rule.get("path") or rule.get("file", "")
                parsed_rules["framework"].append(RuleMetadata(
                    name=rule["name"],
                    path=rule_path,
                    category="framework",
                    framework=framework,
                    topics=self._extract_topics_from_path(rule_path),
                    estimated_tokens=rule.get("estimatedTokens", 1200)
                ))

        # Parse cloud rules
        for cloud, rules in index.get("rules", {}).get("cloud", {}).items():
            for rule in rules:
                rule_path = rule.get("path") or rule.get("file", "")
                parsed_rules["cloud"].append(RuleMetadata(
                    name=rule["name"],
                    path=rule_path,
                    category="cloud",
                    cloud_provider=cloud,
                    topics=self._extract_topics_from_path(rule_path),
                    estimated_tokens=rule.get("estimatedTokens", 1400)
                ))

        return parsed_rules

    def parse_agents_md(self) -> Dict:
        """Parse AGENTS.md to extract rule configuration"""
        if not self.agents_path.exists():
            return {
                "rules": [],
                "patterns": [],
                "total_references": 0,
                "languages_covered": []
            }

        with open(self.agents_path) as f:
            content = f.read()

        # Extract rule references from AGENTS.md
        rule_refs = []

        # Pattern: Look for markdown links to rule files
        # Example: [Code Quality](base/code-quality.md)
        link_pattern = r'\[([^\]]+)\]\(([^)]+\.md)\)'
        for match in re.finditer(link_pattern, content):
            title, path = match.groups()
            rule_refs.append({
                "title": title,
                "path": path
            })

        # Extract coding patterns and best practices
        patterns = []

        # Look for code blocks with language specification
        code_pattern = r'```(\w+)\n(.*?)```'
        for match in re.finditer(code_pattern, content, re.DOTALL):
            language, code = match.groups()
            patterns.append({
                "language": language,
                "code_sample": code.strip()
            })

        return {
            "rules": rule_refs,
            "patterns": patterns,
            "total_references": len(rule_refs),
            "languages_covered": list(set(p["language"] for p in patterns))
        }

    def generate_selection_report(
        self,
        project_languages: List[str],
        project_frameworks: List[str],
        project_cloud: List[str],
        project_maturity: str
    ) -> Dict:
        """Generate comprehensive rules selection report"""

        all_rules = self.parse_index()
        selected_rules = []
        selection_reasoning = []

        # Always include critical base rules
        critical_base = ["code-quality", "security-principles", "git-workflow"]
        for rule in all_rules["base"]:
            rule_basename = Path(rule.path).stem
            if rule_basename in critical_base:
                selected_rules.append(rule)
                selection_reasoning.append({
                    "rule": rule.name,
                    "reason": "Critical base rule",
                    "score": 100
                })

        # Select language-specific rules
        for rule in all_rules["language"]:
            if rule.language in project_languages:
                selected_rules.append(rule)
                selection_reasoning.append({
                    "rule": rule.name,
                    "reason": f"Matches project language: {rule.language}",
                    "score": 90
                })

        # Select framework-specific rules
        for rule in all_rules["framework"]:
            if rule.framework in project_frameworks:
                selected_rules.append(rule)
                selection_reasoning.append({
                    "rule": rule.name,
                    "reason": f"Matches project framework: {rule.framework}",
                    "score": 90
                })

        # Select cloud-specific rules
        for rule in all_rules["cloud"]:
            if rule.cloud_provider in project_cloud:
                selected_rules.append(rule)
                selection_reasoning.append({
                    "rule": rule.name,
                    "reason": f"Matches cloud provider: {rule.cloud_provider}",
                    "score": 85
                })

        # Calculate statistics
        total_available = sum(len(rules) for rules in all_rules.values())
        total_selected = len(selected_rules)
        total_tokens = sum(rule.estimated_tokens for rule in selected_rules)

        return {
            "total_rules_available": total_available,
            "total_rules_selected": total_selected,
            "total_estimated_tokens": total_tokens,
            "selection_efficiency": f"{(total_selected/total_available)*100:.1f}%" if total_available > 0 else "0%",
            "selected_rules": [asdict(rule) for rule in selected_rules],
            "selection_reasoning": selection_reasoning,
            "breakdown": {
                "base": len([r for r in selected_rules if r.category == "base"]),
                "language": len([r for r in selected_rules if r.category == "language"]),
                "framework": len([r for r in selected_rules if r.category == "framework"]),
                "cloud": len([r for r in selected_rules if r.category == "cloud"])
            },
            "project_context": {
                "languages": project_languages,
                "frameworks": project_frameworks,
                "cloud_providers": project_cloud,
                "maturity": project_maturity
            }
        }

    def _extract_topics_from_path(self, rule_path: str) -> List[str]:
        """Extract topics from rule file path"""
        topics = []

        # Extract from filename
        filename = Path(rule_path).stem

        # Common topic keywords
        topic_keywords = {
            "security": ["security", "auth", "jwt", "oauth"],
            "testing": ["testing", "test", "pytest", "jest"],
            "quality": ["quality", "standards", "style"],
            "performance": ["performance", "optimization", "cache"],
            "api": ["api", "rest", "graphql", "endpoint"],
            "database": ["database", "db", "sql", "query"],
            "deployment": ["deployment", "deploy", "ci", "cd"],
        }

        filename_lower = filename.lower()
        for topic, keywords in topic_keywords.items():
            if any(keyword in filename_lower for keyword in keywords):
                topics.append(topic)

        return topics

    def get_all_rule_paths(self) -> List[str]:
        """Get all rule file paths from the repository"""
        rule_paths = []

        # Scan base directory
        base_dir = self.repo_root / "base"
        if base_dir.exists():
            for md_file in base_dir.glob("*.md"):
                rule_paths.append(f"base/{md_file.name}")

        # Scan languages directory
        lang_dir = self.repo_root / "languages"
        if lang_dir.exists():
            for lang_folder in lang_dir.iterdir():
                if lang_folder.is_dir():
                    for md_file in lang_folder.glob("*.md"):
                        rule_paths.append(f"languages/{lang_folder.name}/{md_file.name}")

        # Scan frameworks directory
        fw_dir = self.repo_root / "frameworks"
        if fw_dir.exists():
            for fw_folder in fw_dir.iterdir():
                if fw_folder.is_dir():
                    for md_file in fw_folder.glob("*.md"):
                        rule_paths.append(f"frameworks/{fw_folder.name}/{md_file.name}")

        # Scan cloud directory
        cloud_dir = self.repo_root / "cloud"
        if cloud_dir.exists():
            for cloud_folder in cloud_dir.iterdir():
                if cloud_folder.is_dir():
                    for md_file in cloud_folder.glob("*.md"):
                        rule_paths.append(f"cloud/{cloud_folder.name}/{md_file.name}")

        return sorted(rule_paths)


def main():
    """CLI entry point for testing"""
    import sys

    repo_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    parser = RulesParser(repo_root)

    print("=== Rules Index ===")
    rules = parser.parse_index()
    for category, rule_list in rules.items():
        print(f"{category}: {len(rule_list)} rules")

    print("\n=== AGENTS.md Analysis ===")
    agents_data = parser.parse_agents_md()
    print(f"Rule references: {agents_data['total_references']}")
    print(f"Languages covered: {', '.join(agents_data['languages_covered'])}")

    print("\n=== All Rule Paths ===")
    all_paths = parser.get_all_rule_paths()
    print(f"Total rule files found: {len(all_paths)}")
    for path in all_paths[:10]:
        print(f"  - {path}")
    if len(all_paths) > 10:
        print(f"  ... and {len(all_paths) - 10} more")


if __name__ == "__main__":
    main()
