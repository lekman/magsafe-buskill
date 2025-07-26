# Software Bill of Materials (SBOM) Guide

## Overview

MagSafe Guard includes a Software Bill of Materials (SBOM) to provide complete transparency about the software components and dependencies used in the project. This supports security compliance, vulnerability management, and supply chain security initiatives.

## What is an SBOM?

A Software Bill of Materials (SBOM) is a formal record containing the details and supply chain relationships of various components used in building software. Think of it as an "ingredients list" for software that helps:

- **Track dependencies**: Know exactly what components are included
- **Manage vulnerabilities**: Quickly identify if you're affected by a security issue
- **Ensure compliance**: Meet regulatory and security requirements
- **Verify licenses**: Confirm all components have compatible licenses

## SBOM Format

MagSafe Guard generates its SBOM in **SPDX 2.3** format, which is:

- An international open standard (ISO/IEC 5962:2021)
- Machine-readable and human-readable
- Widely supported by security tools
- Accepted for compliance requirements

## Files Generated

When you run `task sbom`, two files are created:

### 1. `sbom.spdx` (Primary SBOM)

- **Format**: SPDX 2.3 text format
- **Location**: Repository root
- **Contents**:
  - Package metadata (name, version, license)
  - Dependency information
  - Relationships between components
  - Copyright and licensing details

### 2. `sbom-deps.json` (Dependency Details)

- **Format**: JSON
- **Location**: Repository root
- **Contents**: Raw Swift Package Manager dependency tree

## Generating the SBOM

### Prerequisites

Ensure you have `jq` installed:

```bash
brew install jq
```

### Generate SBOM

```bash
# Generate SBOM files
task sbom

# Or if jq is not installed
task sbom:install  # Installs dependencies
task sbom         # Generate SBOM
```

### Verify SBOM

```bash
# View SBOM contents
cat sbom.spdx

# Check JSON dependencies
jq . sbom-deps.json
```

## Using the SBOM

### For Security Teams

1. **Vulnerability Scanning**: Upload `sbom.spdx` to vulnerability scanners
2. **Compliance Audits**: Provide SBOM for software composition analysis
3. **Incident Response**: Quickly check if affected by a CVE

### For Developers

1. **Dependency Review**: Understand the full dependency tree
2. **License Compliance**: Verify all dependencies have compatible licenses
3. **Update Planning**: Track which components need updates

### For Organizations

1. **Procurement**: Include SBOM in software evaluation
2. **Risk Management**: Assess supply chain risks
3. **Compliance**: Meet SBOM requirements (e.g., US Executive Order 14028)

## SBOM Contents Example

```text
SPDXVersion: SPDX-2.3
DataLicense: CC0-1.0
SPDXID: SPDXRef-DOCUMENT
DocumentName: MagSafeGuard
DocumentNamespace: https://github.com/lekman/magsafe-buskill/spdx-v1.5.0-timestamp
Creator: Tool: swift-package-sbom-1.0.0
Created: 2025-01-26T06:44:45Z

PackageName: MagSafeGuard
SPDXID: SPDXRef-Package-MagSafeGuard
PackageVersion: v1.5.0
PackageDownloadLocation: https://github.com/lekman/magsafe-buskill
FilesAnalyzed: false
PackageLicenseConcluded: MIT
PackageLicenseDeclared: MIT
PackageCopyrightText: Copyright (c) 2025 Tobias Lekman

Relationship: SPDXRef-DOCUMENT DESCRIBES SPDXRef-Package-MagSafeGuard
```

## Automation

### CI/CD Integration

The SBOM should be regenerated with each release:

```yaml
# In your CI workflow
- name: Generate SBOM
  run: task sbom
  
- name: Upload SBOM artifacts
  uses: actions/upload-artifact@v3
  with:
    name: sbom
    path: |
      sbom.spdx
      sbom-deps.json
```

### Release Process

1. Update version tags
2. Generate fresh SBOM
3. Include SBOM files in release artifacts
4. Reference SBOM in release notes

## Best Practices

1. **Keep Updated**: Regenerate SBOM when dependencies change
2. **Version Control**: Commit SBOM files to track changes over time
3. **Distribution**: Include SBOM with all distributions
4. **Documentation**: Reference SBOM in security documentation
5. **Validation**: Periodically validate SBOM accuracy

## Tools and Resources

### SBOM Tools

- [SPDX Tools](https://spdx.dev/tools/): Validate and convert SBOM formats
- [SBOM Scorecard](https://github.com/eBay/sbom-scorecard): Assess SBOM quality
- [Syft](https://github.com/anchore/syft): Alternative SBOM generator

### Standards and References

- [SPDX Specification](https://spdx.github.io/spdx-spec/)
- [NTIA SBOM Resources](https://www.ntia.gov/sbom)
- [CISA SBOM Guide](https://www.cisa.gov/sbom)

## Security Considerations

- The SBOM reveals your dependency tree, which is generally not sensitive
- No secrets or private information should be in the SBOM
- SBOM helps security researchers identify and report vulnerabilities
- Transparency improves overall security posture

## Future Enhancements

- [ ] Automated SBOM signing for integrity verification
- [ ] CycloneDX format support as alternative
- [ ] Integration with dependency vulnerability databases
- [ ] SBOM validation in CI/CD pipeline
- [ ] Automated SBOM diff reports between releases

## Questions?

For questions about the SBOM or security practices, please refer to our [Security Policy](../SECURITY.md) or contact security@lekman.com.
