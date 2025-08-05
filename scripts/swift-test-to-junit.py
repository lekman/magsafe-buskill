#!/usr/bin/env python3
"""
Convert Swift test output to JUnit XML format for Codecov Test Analytics
"""

import sys
import re
import xml.etree.ElementTree as ET
from xml.dom import minidom
from datetime import datetime
import argparse

class SwiftTestParser:
    def __init__(self):
        self.test_results = []
        self.current_suite = None
        self.current_test = None
        self.start_time = datetime.now()
        
    def parse_line(self, line):
        # Match test suite start
        suite_match = re.match(r'Test Suite \'(.+)\' started', line)
        if suite_match:
            self.current_suite = suite_match.group(1)
            return
            
        # Match test case start
        test_match = re.match(r'Test Case \'-\[(.+) (.+)\]\' started', line)
        if test_match:
            self.current_test = {
                'classname': test_match.group(1),
                'name': test_match.group(2),
                'time': 0,
                'status': 'passed',
                'message': None,
                'error_type': None
            }
            return
            
        # Match test case passed
        passed_match = re.match(r'Test Case .+ passed \((.+) seconds\)', line)
        if passed_match and self.current_test:
            self.current_test['time'] = float(passed_match.group(1))
            self.test_results.append(self.current_test)
            self.current_test = None
            return
            
        # Match test case failed
        failed_match = re.match(r'Test Case .+ failed \((.+) seconds\)', line)
        if failed_match and self.current_test:
            self.current_test['time'] = float(failed_match.group(1))
            self.current_test['status'] = 'failed'
            self.test_results.append(self.current_test)
            self.current_test = None
            return
            
        # Match test failure details
        error_match = re.match(r'(.+):(\d+): error: (.+) : (.+)', line)
        if error_match and self.current_test:
            self.current_test['error_type'] = 'XCTAssertionFailure'
            self.current_test['message'] = f"{error_match.group(4)} at {error_match.group(1)}:{error_match.group(2)}"
            return
            
        # Match skipped tests
        skip_match = re.match(r'Test .+ skipped', line)
        if skip_match and self.current_test:
            self.current_test['status'] = 'skipped'
            self.test_results.append(self.current_test)
            self.current_test = None
            return
    
    def generate_junit_xml(self):
        # Create root element
        testsuites = ET.Element('testsuites')
        testsuites.set('name', 'MagSafeGuard Tests')
        testsuites.set('tests', str(len(self.test_results)))
        testsuites.set('failures', str(sum(1 for t in self.test_results if t['status'] == 'failed')))
        testsuites.set('errors', '0')
        testsuites.set('time', str(sum(t['time'] for t in self.test_results)))
        testsuites.set('timestamp', self.start_time.isoformat())
        
        # Group tests by classname
        suites = {}
        for test in self.test_results:
            classname = test['classname']
            if classname not in suites:
                suites[classname] = []
            suites[classname].append(test)
        
        # Create test suite elements
        for suite_name, tests in suites.items():
            testsuite = ET.SubElement(testsuites, 'testsuite')
            testsuite.set('name', suite_name)
            testsuite.set('tests', str(len(tests)))
            testsuite.set('failures', str(sum(1 for t in tests if t['status'] == 'failed')))
            testsuite.set('errors', '0')
            testsuite.set('time', str(sum(t['time'] for t in tests)))
            testsuite.set('timestamp', self.start_time.isoformat())
            
            # Create test case elements
            for test in tests:
                testcase = ET.SubElement(testsuite, 'testcase')
                testcase.set('classname', test['classname'])
                testcase.set('name', test['name'])
                testcase.set('time', str(test['time']))
                
                if test['status'] == 'failed':
                    failure = ET.SubElement(testcase, 'failure')
                    failure.set('type', test['error_type'] or 'TestFailure')
                    failure.set('message', test['message'] or 'Test failed')
                    if test['message']:
                        failure.text = test['message']
                elif test['status'] == 'skipped':
                    skipped = ET.SubElement(testcase, 'skipped')
                    skipped.set('message', 'Test skipped')
        
        # Pretty print XML
        rough_string = ET.tostring(testsuites, encoding='unicode')
        reparsed = minidom.parseString(rough_string)
        return reparsed.toprettyxml(indent="  ")

def main():
    parser = argparse.ArgumentParser(description='Convert Swift test output to JUnit XML')
    parser.add_argument('-o', '--output', default='test-results.xml',
                        help='Output file path (default: test-results.xml)')
    args = parser.parse_args()
    
    test_parser = SwiftTestParser()
    
    # Read from stdin
    for line in sys.stdin:
        test_parser.parse_line(line.strip())
    
    # Generate and write XML
    xml_output = test_parser.generate_junit_xml()
    with open(args.output, 'w') as f:
        f.write(xml_output)
    
    print(f"JUnit XML written to {args.output}")
    print(f"Total tests: {len(test_parser.test_results)}")
    print(f"Failures: {sum(1 for t in test_parser.test_results if t['status'] == 'failed')}")
    print(f"Skipped: {sum(1 for t in test_parser.test_results if t['status'] == 'skipped')}")

if __name__ == '__main__':
    main()