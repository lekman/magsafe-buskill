#!/usr/bin/env python3
"""
Format SwiftLint JSON output as SonarCloud-like report.
"""

import json
import sys

def main():
    try:
        with open('.sonarcloud/swiftlint-output.json', 'r') as f:
            issues = json.load(f)
        
        if not issues:
            print('No issues found')
            return
        
        # Limit to first 50 issues
        for i, issue in enumerate(issues[:50]):
            severity = issue.get('severity', 'Warning')
            rule_id = issue.get('rule_id', 'unknown')
            
            # Categorize issue
            if severity == 'Error':
                category = 'BUG'
                level = 'BLOCKER'
            elif 'security' in rule_id.lower() or 'auth' in rule_id.lower():
                category = 'SECURITY_HOTSPOT'
                level = 'CRITICAL'
            else:
                category = 'CODE_SMELL'
                level = 'MINOR'
            
            # Format output
            file_path = issue.get('file', 'unknown')
            line = issue.get('line', 0)
            reason = issue.get('reason', 'No description')
            
            print(f'[{category}] {level}: {file_path}:{line}')
            print(f'  Message: {reason}')
            print(f'  Rule: {rule_id}')
            print()
        
        if len(issues) > 50:
            print(f'\n... and {len(issues) - 50} more issues')
            
    except Exception as e:
        print(f'Error processing SwiftLint output: {e}')

if __name__ == '__main__':
    main()