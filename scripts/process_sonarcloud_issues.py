#!/usr/bin/env python3
"""
Process SonarCloud issues JSON and generate a readable report.
"""

import json
import sys
from datetime import datetime

def main():
    report_path = sys.argv[1] if len(sys.argv) > 1 else '.sonarcloud'
    project_key = sys.argv[2] if len(sys.argv) > 2 else 'lekman_magsafe-buskill'
    
    try:
        with open(f'{report_path}/sonarcloud-issues.json', 'r') as f:
            data = json.load(f)
        
        issues = data.get('issues', [])
        
        # Generate report
        with open(f'{report_path}/sonarcloud-findings.txt', 'w') as report:
            report.write(f'=== SonarCloud Findings Report ===\n')
            report.write(f'Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
            report.write(f'Project: {project_key}\n')
            report.write(f'Total issues: {len(issues)}\n\n')
            
            # Group by severity
            by_severity = {}
            for issue in issues:
                severity = issue.get('severity', 'UNKNOWN')
                if severity not in by_severity:
                    by_severity[severity] = []
                by_severity[severity].append(issue)
            
            # Write issues by severity
            for severity in ['BLOCKER', 'CRITICAL', 'MAJOR', 'MINOR', 'INFO']:
                if severity not in by_severity:
                    continue
                
                report.write(f'\n{"=" * 50}\n')
                report.write(f'{severity} ISSUES ({len(by_severity[severity])})\n')
                report.write(f'{"=" * 50}\n\n')
                
                for issue in by_severity[severity]:
                    component = issue.get('component', 'unknown').replace(f'{project_key}:', '')
                    line = issue.get('textRange', {}).get('startLine', 0)
                    
                    report.write(f'[{issue.get("type", "UNKNOWN")}] {component}:{line}\n')
                    report.write(f'  Rule: {issue.get("rule", "unknown")}\n')
                    report.write(f'  Message: {issue.get("message", "No message")}\n')
                    
                    # Add effort if available
                    effort = issue.get('effort')
                    if effort:
                        report.write(f'  Effort: {effort}\n')
                    
                    # Add status
                    status = issue.get('status', 'OPEN')
                    if status != 'OPEN':
                        report.write(f'  Status: {status}\n')
                    
                    report.write('\n')
        
        print(f'✅ Successfully processed {len(issues)} issues')
        
    except Exception as e:
        print(f'Error processing SonarCloud response: {e}')
        sys.exit(1)

if __name__ == '__main__':
    main()