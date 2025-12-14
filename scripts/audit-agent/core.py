#!/usr/bin/env python3
"""
Repository Audit Agent - Core orchestration
Implements progressive disclosure-aware auditing
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict
from datetime import datetime

# Handle both direct execution and module import
try:
    from .rules_parser import RulesParser
    from .mece_analyzer import MECEAnalyzer
except ImportError:
    from rules_parser import RulesParser
    from mece_analyzer import MECEAnalyzer


@dataclass
class ProjectContext:
    """Detected project context"""
    languages: List[str]
    frameworks: List[str]
    cloud_providers: List[str]
    maturity: str  # mvp, pre-production, production
    working_directory: str


@dataclass
class AuditConfig:
    """Audit configuration"""
    depth: str  # quick, standard, full
    enable_citations: bool = True
    enable_beads_generation: bool = False
    enable_pr_suggestions: bool = True
    max_tasks_per_finding: int = 3


@dataclass
class AuditResult:
    """Complete audit result"""
    timestamp: str
    context: ProjectContext
    rules_selection_report: Dict
    mece_content_map: Optional[Dict] = None
    accuracy_audit: Optional[Dict] = None
    file_disposition: Optional[Dict] = None
    beads_tasks: Optional[List[Dict]] = None
    patch_suggestions: Optional[Dict] = None


class AuditAgent:
    """Main audit agent orchestrator"""

    def __init__(self, repo_root: Path, config: AuditConfig):
        self.repo_root = Path(repo_root)
        self.config = config
        self.context: Optional[ProjectContext] = None

    def run(self) -> AuditResult:
        """Execute complete audit pipeline"""
        print("🔍 Repository Audit Agent Starting...")
        print(f"📁 Repository: {self.repo_root}")
        print(f"⚙️  Audit Depth: {self.config.depth}")
        print()

        # Step 1: Detect project context
        print("[1/6] 🎯 Detecting project context...")
        self.context = self._detect_context()
        print(f"      Languages: {', '.join(self.context.languages) or 'None'}")
        print(f"      Frameworks: {', '.join(self.context.frameworks) or 'None'}")
        print(f"      Cloud: {', '.join(self.context.cloud_providers) or 'None'}")
        print(f"      Maturity: {self.context.maturity}")
        print()

        # Step 2: Generate rules selection report
        print("[2/6] 📋 Generating rules selection report...")
        rules_report = self._generate_rules_report()
        print(f"      Total rules available: {rules_report['total_rules_available']}")
        print(f"      Rules selected: {rules_report['total_rules_selected']}")
        print(f"      Estimated tokens: {rules_report['total_estimated_tokens']}")
        print(f"      Selection efficiency: {rules_report['selection_efficiency']}")
        print()

        # Step 3: MECE content map (if depth >= standard)
        mece_map = None
        if self.config.depth in ['standard', 'full']:
            print("[3/6] 🗺️  Creating MECE content map...")
            mece_map = self._create_mece_map()
            print(f"      Files analyzed: {mece_map.get('files_analyzed', 0)}")
            print(f"      Overlaps found: {mece_map.get('total_overlaps', 0)}")
            print(f"      Coverage gaps: {mece_map.get('total_gaps', 0)}")
            print(f"      MECE score: {mece_map.get('summary', {}).get('mece_score', 'N/A')}")
            print()
        else:
            print("[3/6] ⏭️  Skipping MECE analysis (quick mode)")
            print()

        # Step 4: Accuracy audit (if depth == full)
        accuracy = None
        if self.config.depth == 'full' and self.config.enable_citations:
            print("[4/6] ✅ Running accuracy audit...")
            accuracy = self._run_accuracy_audit()
            print(f"      Files audited: {accuracy.get('files_audited', 0)}")
            print()
        else:
            print("[4/6] ⏭️  Skipping accuracy audit (not full mode)")
            print()

        # Step 5: File disposition
        disposition = None
        if self.config.depth in ['standard', 'full']:
            print("[5/6] 🗂️  Analyzing file disposition...")
            disposition = self._analyze_disposition()
            print(f"      Files classified: {disposition.get('total_files', 0)}")
            print()
        else:
            print("[5/6] ⏭️  Skipping disposition analysis (quick mode)")
            print()

        # Step 6: Generate outputs
        print("[6/6] 📝 Generating final reports...")

        result = AuditResult(
            timestamp=datetime.now().isoformat(),
            context=self.context,
            rules_selection_report=rules_report,
            mece_content_map=mece_map,
            accuracy_audit=accuracy,
            file_disposition=disposition,
        )

        print("✅ Audit complete!")
        return result

    def _detect_context(self) -> ProjectContext:
        """Detect project context from repository"""
        # Simple detection based on file existence
        languages = []
        frameworks = []
        cloud_providers = []

        # Check for language indicators
        if (self.repo_root / "requirements.txt").exists() or (self.repo_root / "pyproject.toml").exists():
            languages.append("python")
        if (self.repo_root / "package.json").exists():
            if (self.repo_root / "tsconfig.json").exists():
                languages.append("typescript")
            else:
                languages.append("javascript")
        if (self.repo_root / "go.mod").exists():
            languages.append("go")
        if (self.repo_root / "pom.xml").exists() or (self.repo_root / "build.gradle").exists():
            languages.append("java")
        if (self.repo_root / "Cargo.toml").exists():
            languages.append("rust")

        # Check for cloud providers
        if (self.repo_root / "terraform").exists():
            cloud_providers.append("aws")
        if (self.repo_root / "vercel.json").exists():
            cloud_providers.append("vercel")

        # Determine maturity from version or presence of CI/CD
        maturity = "mvp"
        if (self.repo_root / ".github" / "workflows").exists():
            if (self.repo_root / "Dockerfile").exists():
                maturity = "production"
            else:
                maturity = "pre-production"

        return ProjectContext(
            languages=languages,
            frameworks=frameworks,
            cloud_providers=cloud_providers,
            maturity=maturity,
            working_directory=str(self.repo_root)
        )

    def _generate_rules_report(self) -> Dict:
        """Generate rules selection report using RulesParser"""
        parser = RulesParser(self.repo_root)

        # Generate comprehensive selection report
        report = parser.generate_selection_report(
            project_languages=self.context.languages,
            project_frameworks=self.context.frameworks,
            project_cloud=self.context.cloud_providers,
            project_maturity=self.context.maturity
        )

        # Parse AGENTS.md for additional context
        agents_data = parser.parse_agents_md()

        return {
            **report,
            "agents_md_analysis": {
                "total_references": agents_data["total_references"],
                "languages_covered": agents_data["languages_covered"]
            }
        }

    def _create_mece_map(self) -> Dict:
        """Create MECE content map using MECEAnalyzer"""
        analyzer = MECEAnalyzer(self.repo_root)
        return analyzer.analyze()

    def _run_accuracy_audit(self) -> Dict:
        """Run accuracy audit with citations"""
        # Placeholder for accuracy audit
        return {
            "files_audited": 0,
            "issues_found": 0,
            "status": "not_implemented_yet"
        }

    def _analyze_disposition(self) -> Dict:
        """Analyze file disposition"""
        # Check for archive directory
        archive_dir = self.repo_root / "archive"
        archive_files = list(archive_dir.glob("*.md")) if archive_dir.exists() else []

        return {
            "total_files": len(archive_files),
            "redundant": len(archive_files),
            "obsolete": len(archive_files),
            "unused": 0,
            "active": 0,
            "recommendations": [
                {
                    "file": str(f.relative_to(self.repo_root)),
                    "status": "obsolete",
                    "action": "delete"
                } for f in archive_files[:5]  # Show first 5
            ]
        }


def main():
    """CLI entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Repository Audit Agent")
    parser.add_argument("--repo", default=".", help="Repository root path")
    parser.add_argument("--depth", choices=["quick", "standard", "full"], default="standard", help="Audit depth")
    parser.add_argument("--output", help="Output file (JSON)")

    args = parser.parse_args()

    config = AuditConfig(depth=args.depth)
    agent = AuditAgent(Path(args.repo), config)
    result = agent.run()

    # Save output
    output_file = args.output or f"audit-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
    output_path = Path(output_file)

    with open(output_path, 'w') as f:
        json.dump(asdict(result), f, indent=2)

    print(f"\n📄 Report saved to: {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
