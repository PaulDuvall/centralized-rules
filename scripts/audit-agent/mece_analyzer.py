#!/usr/bin/env python3
"""
MECE Analyzer - Checks for Mutually Exclusive, Collectively Exhaustive content
Analyzes rules repository for overlaps and coverage gaps
"""

import re
from pathlib import Path
from typing import Dict, List, Set, Tuple
from dataclasses import dataclass, asdict
from collections import defaultdict


@dataclass
class ContentAnalysis:
    """Analysis of a single rule file"""
    file_path: str
    category: str  # base, language, framework, cloud
    topics: Set[str]
    keywords: Set[str]
    headings: List[str]
    code_blocks: List[str]
    word_count: int


@dataclass
class OverlapReport:
    """Report of content overlap between files"""
    file1: str
    file2: str
    overlap_score: float
    common_keywords: List[str]
    common_topics: List[str]


@dataclass
class GapReport:
    """Report of content gaps"""
    category: str
    missing_topics: List[str]
    recommendation: str


class MECEAnalyzer:
    """Analyze repository for MECE compliance"""

    def __init__(self, repo_root: Path):
        self.repo_root = Path(repo_root)

        # Expected topics for each category
        self.expected_topics = {
            "base": [
                "code-quality", "security", "testing", "git", "architecture",
                "refactoring", "documentation", "error-handling", "logging"
            ],
            "language": {
                "python": ["coding-standards", "testing", "async", "packaging"],
                "typescript": ["coding-standards", "testing", "types", "async"],
                "go": ["coding-standards", "testing", "concurrency", "error-handling"],
                "java": ["coding-standards", "testing", "spring", "design-patterns"],
                "rust": ["coding-standards", "testing", "ownership", "error-handling"],
            },
            "framework": {
                "fastapi": ["routing", "async", "testing", "validation", "auth"],
                "django": ["models", "views", "testing", "authentication", "admin"],
                "react": ["components", "hooks", "testing", "state", "routing"],
                "nextjs": ["routing", "ssr", "api-routes", "testing", "optimization"],
            },
            "cloud": {
                "aws": ["iam", "security", "deployment", "monitoring", "cost-optimization"],
                "vercel": ["deployment", "environment", "performance", "preview"],
            }
        }

    def analyze(self) -> Dict:
        """Run complete MECE analysis"""
        # Analyze all rule files
        analyses = self._analyze_all_files()

        # Check for overlaps
        overlaps = self._find_overlaps(analyses)

        # Check for gaps
        gaps = self._find_gaps(analyses)

        return {
            "files_analyzed": len(analyses),
            "total_overlaps": len(overlaps),
            "total_gaps": len(gaps),
            "overlap_reports": [asdict(o) for o in overlaps[:10]],  # Top 10
            "gap_reports": [asdict(g) for g in gaps],
            "summary": self._generate_summary(analyses, overlaps, gaps)
        }

    def _analyze_all_files(self) -> List[ContentAnalysis]:
        """Analyze all markdown files in the repository"""
        analyses = []

        # Analyze base files
        base_dir = self.repo_root / "base"
        if base_dir.exists():
            for md_file in base_dir.glob("*.md"):
                analyses.append(self._analyze_file(md_file, "base"))

        # Analyze language files
        lang_dir = self.repo_root / "languages"
        if lang_dir.exists():
            for lang_folder in lang_dir.iterdir():
                if lang_folder.is_dir():
                    for md_file in lang_folder.glob("*.md"):
                        analyses.append(self._analyze_file(md_file, f"language/{lang_folder.name}"))

        # Analyze framework files
        fw_dir = self.repo_root / "frameworks"
        if fw_dir.exists():
            for fw_folder in fw_dir.iterdir():
                if fw_folder.is_dir():
                    for md_file in fw_folder.glob("*.md"):
                        analyses.append(self._analyze_file(md_file, f"framework/{fw_folder.name}"))

        # Analyze cloud files
        cloud_dir = self.repo_root / "cloud"
        if cloud_dir.exists():
            for cloud_folder in cloud_dir.iterdir():
                if cloud_folder.is_dir():
                    for md_file in cloud_folder.glob("*.md"):
                        analyses.append(self._analyze_file(md_file, f"cloud/{cloud_folder.name}"))

        return analyses

    def _analyze_file(self, file_path: Path, category: str) -> ContentAnalysis:
        """Analyze a single markdown file"""
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Extract headings
        headings = re.findall(r'^#+\s+(.+)$', content, re.MULTILINE)

        # Extract code blocks
        code_blocks = re.findall(r'```\w*\n(.*?)```', content, re.DOTALL)

        # Extract keywords (significant words)
        keywords = self._extract_keywords(content)

        # Extract topics from filename and headings
        topics = self._extract_topics(file_path.stem, headings)

        # Count words
        word_count = len(content.split())

        return ContentAnalysis(
            file_path=str(file_path.relative_to(self.repo_root)),
            category=category,
            topics=topics,
            keywords=keywords,
            headings=headings,
            code_blocks=code_blocks,
            word_count=word_count
        )

    def _extract_keywords(self, content: str) -> Set[str]:
        """Extract significant keywords from content"""
        # Remove code blocks first
        content_no_code = re.sub(r'```.*?```', '', content, flags=re.DOTALL)

        # Common technical keywords to look for
        keyword_patterns = [
            r'\b(async|await|promise)\b',
            r'\b(test|testing|pytest|jest)\b',
            r'\b(security|authentication|authorization)\b',
            r'\b(api|endpoint|route|handler)\b',
            r'\b(database|query|sql|orm)\b',
            r'\b(deployment|ci|cd|docker)\b',
            r'\b(error|exception|logging)\b',
            r'\b(performance|optimization|cache)\b',
        ]

        keywords = set()
        for pattern in keyword_patterns:
            matches = re.findall(pattern, content_no_code, re.IGNORECASE)
            keywords.update(m.lower() for m in matches)

        return keywords

    def _extract_topics(self, filename: str, headings: List[str]) -> Set[str]:
        """Extract topics from filename and headings"""
        topics = set()

        # Add filename as topic (normalized)
        topics.add(filename.lower().replace('-', ' '))

        # Extract from headings
        for heading in headings:
            # Normalize heading
            normalized = heading.lower().strip()
            normalized = re.sub(r'[^\w\s-]', '', normalized)
            topics.add(normalized)

        return topics

    def _find_overlaps(self, analyses: List[ContentAnalysis]) -> List[OverlapReport]:
        """Find overlapping content between files"""
        overlaps = []

        for i, analysis1 in enumerate(analyses):
            for analysis2 in analyses[i+1:]:
                # Skip if same category (some overlap is expected)
                if analysis1.category != analysis2.category:
                    continue

                # Calculate overlap
                common_keywords = analysis1.keywords & analysis2.keywords
                common_topics = analysis1.topics & analysis2.topics

                if len(common_keywords) > 3 or len(common_topics) > 2:
                    # Calculate overlap score
                    keyword_overlap = len(common_keywords) / max(len(analysis1.keywords), len(analysis2.keywords))
                    topic_overlap = len(common_topics) / max(len(analysis1.topics), len(analysis2.topics))
                    overlap_score = (keyword_overlap + topic_overlap) / 2

                    if overlap_score > 0.3:  # More than 30% overlap
                        overlaps.append(OverlapReport(
                            file1=analysis1.file_path,
                            file2=analysis2.file_path,
                            overlap_score=round(overlap_score, 2),
                            common_keywords=sorted(list(common_keywords))[:10],
                            common_topics=sorted(list(common_topics))[:5]
                        ))

        # Sort by overlap score (descending)
        overlaps.sort(key=lambda x: x.overlap_score, reverse=True)

        return overlaps

    def _find_gaps(self, analyses: List[ContentAnalysis]) -> List[GapReport]:
        """Find coverage gaps in the repository"""
        gaps = []

        # Check base topics
        base_analyses = [a for a in analyses if a.category == "base"]
        base_topics = set()
        for analysis in base_analyses:
            base_topics.update(analysis.topics)

        for expected in self.expected_topics["base"]:
            found = any(expected.replace('-', ' ') in ' '.join(base_topics) for expected in [expected])
            if not found:
                gaps.append(GapReport(
                    category="base",
                    missing_topics=[expected],
                    recommendation=f"Create base/{expected}.md to cover {expected.replace('-', ' ')} best practices"
                ))

        # Check language topics
        lang_analyses = defaultdict(list)
        for analysis in analyses:
            if analysis.category.startswith("language/"):
                lang = analysis.category.split("/")[1]
                lang_analyses[lang].append(analysis)

        for lang, expected_topics in self.expected_topics.get("language", {}).items():
            if lang not in lang_analyses:
                gaps.append(GapReport(
                    category=f"language/{lang}",
                    missing_topics=expected_topics,
                    recommendation=f"Add {lang} language support with rules covering {', '.join(expected_topics)}"
                ))
                continue

            lang_topics = set()
            for analysis in lang_analyses[lang]:
                lang_topics.update(analysis.topics)

            for expected in expected_topics:
                found = any(expected.replace('-', ' ') in ' '.join(lang_topics) for expected in [expected])
                if not found:
                    gaps.append(GapReport(
                        category=f"language/{lang}",
                        missing_topics=[expected],
                        recommendation=f"Add languages/{lang}/{expected}.md"
                    ))

        return gaps

    def _generate_summary(self, analyses: List[ContentAnalysis], overlaps: List[OverlapReport], gaps: List[GapReport]) -> Dict:
        """Generate analysis summary"""
        # Count by category
        category_counts = defaultdict(int)
        for analysis in analyses:
            base_category = analysis.category.split("/")[0]
            category_counts[base_category] += 1

        return {
            "total_files": len(analyses),
            "by_category": dict(category_counts),
            "high_overlap_count": len([o for o in overlaps if o.overlap_score > 0.5]),
            "critical_gaps": len([g for g in gaps if g.category == "base"]),
            "mece_score": self._calculate_mece_score(len(overlaps), len(gaps), len(analyses))
        }

    def _calculate_mece_score(self, overlaps: int, gaps: int, total_files: int) -> str:
        """Calculate MECE compliance score"""
        # Penalize for overlaps and gaps
        penalty = (overlaps * 2) + (gaps * 3)
        score = max(0, 100 - penalty)

        if score >= 90:
            return f"{score}% - Excellent"
        elif score >= 70:
            return f"{score}% - Good"
        elif score >= 50:
            return f"{score}% - Fair"
        else:
            return f"{score}% - Needs Improvement"


def main():
    """CLI entry point"""
    import sys
    import json

    repo_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    analyzer = MECEAnalyzer(repo_root)

    print("Running MECE analysis...")
    result = analyzer.analyze()

    print("\n=== MECE Analysis Results ===")
    print(f"Files analyzed: {result['files_analyzed']}")
    print(f"Overlaps found: {result['total_overlaps']}")
    print(f"Gaps found: {result['total_gaps']}")
    print(f"\nMECE Score: {result['summary']['mece_score']}")

    if result['overlap_reports']:
        print("\n=== Top Overlaps ===")
        for overlap in result['overlap_reports'][:3]:
            print(f"\n{overlap['file1']} <-> {overlap['file2']}")
            print(f"  Overlap: {overlap['overlap_score']*100:.0f}%")
            print(f"  Common keywords: {', '.join(overlap['common_keywords'][:5])}")

    if result['gap_reports']:
        print("\n=== Coverage Gaps ===")
        for gap in result['gap_reports'][:5]:
            print(f"\n{gap['category']}")
            print(f"  Missing: {', '.join(gap['missing_topics'])}")
            print(f"  Recommendation: {gap['recommendation']}")

    # Save full report
    output_file = "mece-analysis.json"
    with open(output_file, 'w') as f:
        json.dump(result, f, indent=2)
    print(f"\nFull report saved to: {output_file}")


if __name__ == "__main__":
    main()
