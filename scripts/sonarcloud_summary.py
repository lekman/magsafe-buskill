#!/usr/bin/env python3
"""
Generate summary of SonarCloud issues.
"""

import json
import sys

def main():
    report_path = sys.argv[1] if len(sys.argv) > 1 else '.sonarcloud'
    
    with open(f'{report_path}/sonarcloud-issues.json', 'r') as f:
        data = json.load(f)
        issues = data.get('issues', [])
        
        # Count by type
        types = {}
        severities = {}
        for issue in issues:
            issue_type = issue.get('type', 'UNKNOWN')
            severity = issue.get('severity', 'UNKNOWN')
            types[issue_type] = types.get(issue_type, 0) + 1
            severities[severity] = severities.get(severity, 0) + 1
        
        print('By Type:')
        for t, count in sorted(types.items()):
            print(f'  - {t}: {count}')
        
        print('\nBy Severity:')
        for s in ['BLOCKER', 'CRITICAL', 'MAJOR', 'MINOR', 'INFO']:
            if s in severities:
                print(f'  - {s}: {severities[s]}')

if __name__ == '__main__':
    main()