# Copilot Instructions - Setup Guide

This directory contains instructions for GitHub Copilot to assist with development in this repository.

## Files Overview

### Main Instructions
- **`copilot-instructions.md`** - Primary instructions for Copilot
  - Section 1-4: Reviewing Dependabot gem upgrade PRs
  - Section 5: Implementing gem upgrade fixes using feature flags

### Specialized Instructions
- **`instructions/gem-upgrades.instructions.md`** - Detailed gem upgrade implementation guide (mirrors section 5 of main instructions)

## Key Patterns

### Dependency Upgrade Pattern

All dependency upgrades in this repository use the `K2Config.dependency_upgraded_next?` feature flag pattern.

**Core principle**: Never modify old code paths - only add new code behind the feature flag.

```ruby
if K2Config.dependency_upgraded_next?
  # New code for upgraded gems
  # Add comment with changelog link
else
  # Original code - DO NOT MODIFY
end
```

### Documentation Requirements

1. **Inline comments** - Explain what changed and why, with changelog links
2. **Changelog updates** - Document in `docs/dependency-upgrades-changelog.md`
3. **Draft PRs** - Start with draft, mark ready after testing

## Related Documentation

- `docs/FEATURE_FLAG_PATTERN.md` - Comprehensive guide to the feature flag pattern
- `docs/dependency-upgrades-changelog.md` - Tracking log for all upgrades
- `config/k2_config.rb` - Feature flag module implementation

## Testing

The feature flag is controlled via environment variable:

```bash
# Test with current dependencies (default)
bundle exec rspec

# Test with upgraded dependencies
DEPENDENCY_UPGRADED_NEXT=true bundle exec rspec
```

CI runs both modes to ensure neither code path breaks.

## Best Practices

1. **Review first** - Use sections 1-4 to review Dependabot PRs
2. **Implement carefully** - Use section 5 pattern for code changes
3. **Document thoroughly** - Add comments and changelog entries
4. **Test both paths** - Verify old and new behavior works
5. **Draft then ready** - Start draft, mark ready after verification

## Questions?

For detailed information, see:
- `docs/FEATURE_FLAG_PATTERN.md` for the pattern guide
- `.github/copilot-instructions.md` for Copilot-specific instructions
