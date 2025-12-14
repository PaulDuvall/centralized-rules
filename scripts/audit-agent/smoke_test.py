#!/usr/bin/env python3
"""
Smoke tests for audit agent - no external dependencies required
Run these tests to verify basic functionality
"""

import sys
import json
from pathlib import Path
from tempfile import TemporaryDirectory

# Import modules to test
from rules_parser import RulesParser
from mece_analyzer import MECEAnalyzer
from core import AuditAgent, AuditConfig


def test_rules_parser():
    """Test basic RulesParser functionality"""
    print("Testing RulesParser...")

    with TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)

        # Test 1: Parse empty index
        parser = RulesParser(tmp_path)
        result = parser.parse_index()
        assert result["base"] == [], "Empty base rules failed"
        assert result["language"] == [], "Empty language rules failed"
        print("  ✓ Parse empty index")

        # Test 2: Parse with base rules
        rules_dir = tmp_path / ".claude" / "rules"
        rules_dir.mkdir(parents=True)

        index = {
            "rules": {
                "base": [
                    {"name": "Code Quality", "file": "base/code-quality.md"},
                    {"name": "Security", "file": "base/security.md"}
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
        assert len(result["base"]) == 2, "Base rules count failed"
        assert result["base"][0].name == "Code Quality", "Rule name failed"
        print("  ✓ Parse with base rules")

        # Test 3: Topic extraction
        topics = parser._extract_topics_from_path("base/security-principles.md")
        assert "security" in topics, "Topic extraction failed"
        print("  ✓ Extract topics from path")

    print("✅ RulesParser tests passed\n")


def test_mece_analyzer():
    """Test basic MECEAnalyzer functionality"""
    print("Testing MECEAnalyzer...")

    with TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)

        # Test 1: Empty repository
        analyzer = MECEAnalyzer(tmp_path)
        result = analyzer.analyze()
        assert result["files_analyzed"] == 0, "Empty repo analysis failed"
        print("  ✓ Analyze empty repository")

        # Test 2: With base files
        base_dir = tmp_path / "base"
        base_dir.mkdir()

        (base_dir / "code-quality.md").write_text("""
# Code Quality
Quality guidelines.

## Testing
Write tests.

## Security
Follow security practices.
        """)

        (base_dir / "security.md").write_text("""
# Security
Security best practices.

## Testing
Test security implementations.
        """)

        analyzer = MECEAnalyzer(tmp_path)
        result = analyzer.analyze()
        assert result["files_analyzed"] == 2, "Files count failed"
        print("  ✓ Analyze with base files")

        # Test 3: Keyword extraction
        content = "This covers async operations and testing with pytest."
        keywords = analyzer._extract_keywords(content)
        assert len(keywords) > 0, "Keyword extraction failed"
        print("  ✓ Extract keywords")

        # Test 4: MECE score
        score = analyzer._calculate_mece_score(0, 0, 10)
        assert "100%" in score, "MECE score calculation failed"
        print("  ✓ Calculate MECE score")

    print("✅ MECEAnalyzer tests passed\n")


def test_audit_agent():
    """Test basic AuditAgent functionality"""
    print("Testing AuditAgent...")

    with TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)

        # Test 1: Context detection - empty repo
        config = AuditConfig(depth="quick")
        agent = AuditAgent(tmp_path, config)
        context = agent._detect_context()
        assert context.languages == [], "Empty repo detection failed"
        print("  ✓ Detect context for empty repo")

        # Test 2: Context detection - Python project
        (tmp_path / "requirements.txt").write_text("pytest\n")
        agent = AuditAgent(tmp_path, config)
        context = agent._detect_context()
        assert "python" in context.languages, "Python detection failed"
        print("  ✓ Detect Python project")

        # Test 3: Context detection - TypeScript project
        tmp_path2 = Path(tmp_dir) / "ts_project"
        tmp_path2.mkdir()
        (tmp_path2 / "package.json").write_text('{"name": "test"}')
        (tmp_path2 / "tsconfig.json").write_text('{}')

        agent = AuditAgent(tmp_path2, config)
        context = agent._detect_context()
        assert "typescript" in context.languages, "TypeScript detection failed"
        print("  ✓ Detect TypeScript project")

        # Test 4: Quick audit run
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

        agent = AuditAgent(tmp_path, config)
        result = agent.run()

        assert result.context is not None, "Context is None"
        assert result.rules_selection_report is not None, "Rules report is None"
        assert result.mece_content_map is None, "MECE should be None in quick mode"
        print("  ✓ Run quick audit")

    print("✅ AuditAgent tests passed\n")


def test_integration():
    """Test full integration"""
    print("Testing Integration...")

    with TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)

        # Set up realistic project
        (tmp_path / "package.json").write_text('{"name": "test"}')
        (tmp_path / "tsconfig.json").write_text('{}')

        # Create rules
        rules_dir = tmp_path / ".claude" / "rules"
        rules_dir.mkdir(parents=True)

        index = {
            "rules": {
                "base": [{"name": "Code Quality", "file": "base/code-quality.md"}],
                "languages": {"typescript": [{"name": "TS Standards", "file": "lang/ts.md"}]},
                "frameworks": {},
                "cloud": {}
            }
        }

        with open(rules_dir / "index.json", 'w') as f:
            json.dump(index, f)

        # Create base directory
        base_dir = tmp_path / "base"
        base_dir.mkdir()
        (base_dir / "code-quality.md").write_text("# Code Quality\nGuidelines.")

        # Run standard audit
        config = AuditConfig(depth="standard")
        agent = AuditAgent(tmp_path, config)
        result = agent.run()

        assert "typescript" in result.context.languages, "Integration: TS not detected"
        assert result.rules_selection_report["total_rules_available"] >= 1, "Integration: No rules"
        assert result.mece_content_map is not None, "Integration: No MECE map"
        assert result.mece_content_map["files_analyzed"] >= 1, "Integration: No files analyzed"
        print("  ✓ Full audit workflow")

    print("✅ Integration tests passed\n")


def main():
    """Run all smoke tests"""
    print("=" * 50)
    print("Running Audit Agent Smoke Tests")
    print("=" * 50)
    print()

    try:
        test_rules_parser()
        test_mece_analyzer()
        test_audit_agent()
        test_integration()

        print("=" * 50)
        print("✅ ALL TESTS PASSED")
        print("=" * 50)
        return 0

    except AssertionError as e:
        print(f"\n❌ TEST FAILED: {e}")
        return 1
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
