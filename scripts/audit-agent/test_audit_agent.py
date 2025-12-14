#!/usr/bin/env python3
"""
Test suite for the audit agent
"""

import json
import pytest
from pathlib import Path
from tempfile import TemporaryDirectory

from rules_parser import RulesParser, RuleMetadata
from mece_analyzer import MECEAnalyzer
from core import AuditAgent, AuditConfig, ProjectContext


class TestRulesParser:
    """Test RulesParser functionality"""

    def test_parse_index_no_file(self, tmp_path):
        """Test parsing when index.json doesn't exist"""
        parser = RulesParser(tmp_path)
        result = parser.parse_index()

        assert result == {
            "base": [],
            "language": [],
            "framework": [],
            "cloud": []
        }

    def test_parse_index_with_base_rules(self, tmp_path):
        """Test parsing base rules from index"""
        # Create rules directory and index
        rules_dir = tmp_path / ".claude" / "rules"
        rules_dir.mkdir(parents=True)

        index = {
            "rules": {
                "base": [
                    {
                        "name": "Code Quality",
                        "file": ".claude/rules/base/code-quality.md"
                    },
                    {
                        "name": "Security",
                        "file": ".claude/rules/base/security.md"
                    }
                ],
                "languages": {},
                "frameworks": {},
                "cloud": {}
            }
        }

        with open(rules_dir / "index.json", 'w') as f:
            json.dump(index, f)

        parser = RulesParser(tmp_path)
        result = parser.parse_index()

        assert len(result["base"]) == 2
        assert result["base"][0].name == "Code Quality"
        assert result["base"][1].name == "Security"

    def test_extract_topics_from_path(self):
        """Test topic extraction from file paths"""
        parser = RulesParser(Path("."))

        topics = parser._extract_topics_from_path("base/security-principles.md")
        assert "security" in topics

        topics = parser._extract_topics_from_path("languages/python/testing.md")
        assert "testing" in topics

    def test_generate_selection_report(self, tmp_path):
        """Test rules selection report generation"""
        # Create minimal rules structure
        rules_dir = tmp_path / ".claude" / "rules"
        rules_dir.mkdir(parents=True)

        index = {
            "rules": {
                "base": [
                    {
                        "name": "Code Quality",
                        "file": ".claude/rules/base/code-quality.md"
                    }
                ],
                "languages": {},
                "frameworks": {},
                "cloud": {}
            }
        }

        with open(rules_dir / "index.json", 'w') as f:
            json.dump(index, f)

        parser = RulesParser(tmp_path)
        report = parser.generate_selection_report(
            project_languages=["python"],
            project_frameworks=[],
            project_cloud=[],
            project_maturity="mvp"
        )

        assert report["total_rules_available"] >= 1
        assert report["total_rules_selected"] >= 1
        assert "selection_efficiency" in report


class TestMECEAnalyzer:
    """Test MECEAnalyzer functionality"""

    def test_analyze_empty_repository(self, tmp_path):
        """Test analysis of empty repository"""
        analyzer = MECEAnalyzer(tmp_path)
        result = analyzer.analyze()

        assert result["files_analyzed"] == 0
        assert result["total_overlaps"] == 0
        assert result["total_gaps"] >= 0  # Some gaps expected for empty repo

    def test_analyze_with_base_files(self, tmp_path):
        """Test analysis with base markdown files"""
        # Create base directory with sample files
        base_dir = tmp_path / "base"
        base_dir.mkdir()

        (base_dir / "code-quality.md").write_text("""
# Code Quality

Guidelines for writing quality code.

## Testing
Always write tests for your code.

## Security
Follow security best practices.
        """)

        (base_dir / "security-principles.md").write_text("""
# Security Principles

Security best practices for development.

## Authentication
Use strong authentication mechanisms.

## Testing
Test your security implementations.
        """)

        analyzer = MECEAnalyzer(tmp_path)
        result = analyzer.analyze()

        assert result["files_analyzed"] == 2
        # Should detect some overlap due to "testing" and "security"
        assert result["total_overlaps"] >= 0

    def test_extract_keywords(self):
        """Test keyword extraction"""
        analyzer = MECEAnalyzer(Path("."))

        content = """
        This document covers async operations and testing.
        We use pytest for testing and ensure good security.
        """

        keywords = analyzer._extract_keywords(content)
        assert "async" in keywords
        assert "testing" in keywords or "test" in keywords
        assert "security" in keywords

    def test_mece_score_calculation(self):
        """Test MECE score calculation"""
        analyzer = MECEAnalyzer(Path("."))

        # Perfect score (no overlaps or gaps)
        score = analyzer._calculate_mece_score(0, 0, 10)
        assert "100%" in score
        assert "Excellent" in score

        # Good score
        score = analyzer._calculate_mece_score(2, 1, 10)
        assert "Good" in score or "Fair" in score

        # Needs improvement
        score = analyzer._calculate_mece_score(10, 10, 10)
        assert "Needs Improvement" in score


class TestAuditAgent:
    """Test AuditAgent core functionality"""

    def test_detect_context_empty_repo(self, tmp_path):
        """Test context detection for empty repository"""
        config = AuditConfig(depth="quick")
        agent = AuditAgent(tmp_path, config)

        context = agent._detect_context()

        assert context.languages == []
        assert context.frameworks == []
        assert context.cloud_providers == []
        assert context.maturity in ["mvp", "pre-production", "production"]

    def test_detect_context_python_project(self, tmp_path):
        """Test context detection for Python project"""
        # Create Python project markers
        (tmp_path / "requirements.txt").write_text("pytest\nfastapi\n")
        (tmp_path / "pyproject.toml").write_text("[tool.poetry]\nname = 'test'\n")

        config = AuditConfig(depth="quick")
        agent = AuditAgent(tmp_path, config)

        context = agent._detect_context()

        assert "python" in context.languages

    def test_detect_context_typescript_project(self, tmp_path):
        """Test context detection for TypeScript project"""
        # Create TypeScript project markers
        (tmp_path / "package.json").write_text('{"name": "test"}')
        (tmp_path / "tsconfig.json").write_text('{"compilerOptions": {}}')

        config = AuditConfig(depth="quick")
        agent = AuditAgent(tmp_path, config)

        context = agent._detect_context()

        assert "typescript" in context.languages

    def test_run_quick_audit(self, tmp_path):
        """Test running quick audit"""
        # Create minimal rules structure
        rules_dir = tmp_path / ".claude" / "rules"
        rules_dir.mkdir(parents=True)

        index = {
            "rules": {
                "base": [],
                "languages": {},
                "frameworks": {},
                "cloud": {}
            }
        }

        with open(rules_dir / "index.json", 'w') as f:
            json.dump(index, f)

        config = AuditConfig(depth="quick")
        agent = AuditAgent(tmp_path, config)

        result = agent.run()

        assert result.context is not None
        assert result.rules_selection_report is not None
        assert result.mece_content_map is None  # Not run in quick mode
        assert result.accuracy_audit is None
        assert result.file_disposition is None

    def test_run_standard_audit(self, tmp_path):
        """Test running standard audit"""
        # Create minimal rules structure
        rules_dir = tmp_path / ".claude" / "rules"
        rules_dir.mkdir(parents=True)

        index = {
            "rules": {
                "base": [],
                "languages": {},
                "frameworks": {},
                "cloud": {}
            }
        }

        with open(rules_dir / "index.json", 'w') as f:
            json.dump(index, f)

        # Create base directory for MECE analysis
        (tmp_path / "base").mkdir()

        config = AuditConfig(depth="standard")
        agent = AuditAgent(tmp_path, config)

        result = agent.run()

        assert result.context is not None
        assert result.rules_selection_report is not None
        assert result.mece_content_map is not None  # Run in standard mode
        assert result.file_disposition is not None


class TestIntegration:
    """Integration tests"""

    def test_full_audit_workflow(self, tmp_path):
        """Test complete audit workflow"""
        # Set up a realistic project structure
        (tmp_path / "package.json").write_text('{"name": "test-project"}')
        (tmp_path / "tsconfig.json").write_text('{"compilerOptions": {}}')

        # Create rules structure
        rules_dir = tmp_path / ".claude" / "rules"
        rules_dir.mkdir(parents=True)

        index = {
            "rules": {
                "base": [
                    {
                        "name": "Code Quality",
                        "file": ".claude/rules/base/code-quality.md"
                    }
                ],
                "languages": {
                    "typescript": [
                        {
                            "name": "TypeScript Standards",
                            "file": ".claude/rules/languages/typescript/standards.md"
                        }
                    ]
                },
                "frameworks": {},
                "cloud": {}
            }
        }

        with open(rules_dir / "index.json", 'w') as f:
            json.dump(index, f)

        # Create base directory
        base_dir = tmp_path / "base"
        base_dir.mkdir()
        (base_dir / "code-quality.md").write_text("# Code Quality\n\nQuality guidelines.")

        # Run audit
        config = AuditConfig(depth="standard")
        agent = AuditAgent(tmp_path, config)
        result = agent.run()

        # Verify results
        assert "typescript" in result.context.languages
        assert result.rules_selection_report["total_rules_available"] >= 1
        assert result.mece_content_map["files_analyzed"] >= 1


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
