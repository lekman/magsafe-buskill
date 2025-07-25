# CI/CD Caching Strategy

## Overview

To reduce CI build times from 12+ minutes to ~2-3 minutes, we implement comprehensive caching for Swift builds.

## What We Cache

### 1. Swift Package Manager (SPM) Build Artifacts

- **Path**: `.build/`
- **Contains**: Compiled object files, modules, and executables
- **Size**: ~50-200MB depending on project

### 2. SPM Cache

- **Path**: `~/.swiftpm/`
- **Contains**: Downloaded package dependencies
- **Size**: Varies based on dependencies

### 3. Xcode Derived Data (macOS only)

- **Path**: `~/Library/Developer/Xcode/DerivedData`
- **Contains**: Xcode build artifacts and indexes
- **Size**: Can be large (100MB-1GB)

### 4. CodeQL Database

- **Path**: `${{ runner.temp }}/codeql_databases`
- **Contains**: CodeQL analysis database
- **Size**: ~100-500MB

## Cache Keys Strategy

### Test Workflow

```yaml
key: ${{ runner.os }}-spm-${{ hashFiles('Package.swift', '**/Package.resolved') }}
restore-keys: |
  ${{ runner.os }}-spm-
```

### Security Workflow (CodeQL)

```yaml
key: ${{ runner.os }}-spm-${{ hashFiles('Package.swift', '**/Package.resolved') }}-${{ hashFiles('Sources/**/*.swift') }}
restore-keys: |
  ${{ runner.os }}-spm-${{ hashFiles('Package.swift', '**/Package.resolved') }}-
  ${{ runner.os }}-spm-
```

## Cache Invalidation

Caches are invalidated when:

1. `Package.swift` changes (new dependencies)
2. `Package.resolved` changes (dependency versions)
3. Source files change (for CodeQL workflow)
4. Operating system changes

## Build Optimization

### Incremental Builds

The security workflow checks for cached builds:

```bash
if [ -d ".build/debug" ] && [ -f ".build/debug/MagSafeGuard" ]; then
  echo "Found cached build, verifying..."
  # Touch source files to ensure CodeQL sees them
  find Sources -name "*.swift" -exec touch {} \;
  # Do a quick incremental build
  swift build --configuration debug
else
  echo "No cached build found, building from scratch..."
  swift build --configuration debug --verbose
fi
```

### Benefits

1. **First run**: ~12 minutes (full build)
2. **Subsequent runs**: ~2-3 minutes (cache hit)
3. **After code changes**: ~3-5 minutes (incremental build)

## Cache Management

### GitHub Actions Limits

- Maximum cache size: 10GB per repository
- Eviction policy: Least recently used (LRU)
- Retention: 7 days without use

### Best Practices

1. **Don't cache everything**: Only cache expensive operations
2. **Use restore keys**: Allows partial cache matches
3. **Include file hashes**: Ensures cache correctness
4. **Monitor cache size**: Remove unnecessary paths if too large

## Troubleshooting

### Cache Miss

If builds are still slow:

1. Check cache hit rate in Actions logs
2. Verify cache keys are correct
3. Ensure paths exist and contain expected files

### Cache Corruption

If builds fail with cached artifacts:

1. Clear cache in GitHub Actions settings
2. Update cache key to force rebuild
3. Add version suffix to cache key

## Future Improvements

1. **Separate caches** for dependencies vs build artifacts
2. **ccache** integration for C/C++ compilation
3. **Distributed caching** for multiple runners
4. **Pre-warming** caches on schedule
