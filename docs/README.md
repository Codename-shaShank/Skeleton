# Documentation Index

This directory contains documentation for dependency upgrades and the feature flag pattern.

## Files

### 1. [FEATURE_FLAG_PATTERN.md](FEATURE_FLAG_PATTERN.md)
**The complete guide to the feature flag pattern for dependency upgrades.**

Read this first to understand:
- Why we use feature flags for dependency upgrades
- How the pattern works
- Rules for adding code safely
- Deployment strategy (4 phases)
- Testing both old and new behaviors
- Multiple examples and common pitfalls

### 2. [dependency-upgrades-changelog.md](dependency-upgrades-changelog.md)
**Changelog tracking all dependency upgrades.**

Documents each dependency upgrade:
- What changed in the dependency
- Breaking changes and new features
- Links to relevant changelogs
- Code changes made
- Testing strategy
- Rollback plan

Currently documents:
- pg gem: 0.17.1 → 0.18.4

### 3. [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
**Summary of the pg gem upgrade implementation.**

Specific to the pg 0.17.1 → 0.18.4 upgrade:
- What was implemented
- Why no code changes were required
- Files changed
- How to use the implementation
- Next steps

## Quick Start

### Using the Feature Flag

The `K2Config.dependency_upgraded_next?` feature flag allows you to switch between old and new dependency behaviors:

```bash
# Run with old behavior (default)
bundle exec rspec

# Run with new behavior
K2_DEPENDENCY_UPGRADED_NEXT=true bundle exec rspec
```

### Adding Feature-Flagged Code

When a dependency upgrade requires code changes:

```ruby
if K2Config.dependency_upgraded_next?
  # New dependency version behavior
  # Comment: Explain what changed in new version
  # Changelog: https://github.com/gem-name/repo/blob/master/CHANGELOG.md#version
  new_implementation
else
  # Old dependency version behavior (unchanged)
  old_implementation
end
```

See [FEATURE_FLAG_PATTERN.md](FEATURE_FLAG_PATTERN.md) for complete details.

## Documentation Goals

This documentation aims to:

1. **Enable safe dependency upgrades** - Deploy the same codebase with different dependency versions
2. **Facilitate gradual rollout** - Enable new behavior incrementally in production
3. **Provide instant rollback** - Quickly revert to old behavior if issues arise
4. **Document all changes** - Track what changed and why for each upgrade
5. **Guide future upgrades** - Provide patterns and examples for future work

## Contributing

When adding a new dependency upgrade:

1. Follow the pattern in [FEATURE_FLAG_PATTERN.md](FEATURE_FLAG_PATTERN.md)
2. Document in [dependency-upgrades-changelog.md](dependency-upgrades-changelog.md) using the provided template
3. Add comments with changelog links in your code
4. Test both old and new behaviors
5. Update this README if needed

## Questions?

- **Pattern questions**: See [FEATURE_FLAG_PATTERN.md](FEATURE_FLAG_PATTERN.md)
- **Specific upgrade details**: See [dependency-upgrades-changelog.md](dependency-upgrades-changelog.md)
- **Implementation details**: See [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
