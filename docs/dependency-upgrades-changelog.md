# Dependency Upgrades Changelog

This document tracks changes made to support dependency upgrades while maintaining backward compatibility.

## Overview

All dependency upgrade changes are behind the `K2Config.dependency_upgraded_next?` feature flag to allow:
- Safe deployment with old dependency versions (current production)
- Testing with new dependency versions before full rollout

Set environment variable `K2_DEPENDENCY_UPGRADED_NEXT=true` to enable new dependency behavior.

---

## pg gem: 0.17.1 → 0.18.4

**PR**: [Link to this PR]
**Date**: 2026-02-18
**Change Type**: Minor version upgrade

### What Changed

The pg gem was upgraded from 0.17.1 to 0.18.4. This is a minor version update that includes:

#### Key Enhancements in pg 0.18.x:
- **Type Cast System**: Added an extensible type cast system for better data type handling
- **Performance Improvements**: Significant performance enhancements across the board
- **Frozen Strings**: Result field names are now returned as frozen strings
- **New Methods**: 
  - `PG::Result#stream_each` and `#stream_each_row` for single row mode
  - `PG::Connection#conninfo` and `#hostaddr` for connection information
  - `PG.init_openssl` and `PG.init_ssl` for SSL initialization
- **Better Error Handling**: Improved null byte handling in strings (raises ArgumentError)

#### Breaking Changes:
- OID to Integer mapping is now unsigned (was signed in 0.17.x)
- Strings with null bytes now raise ArgumentError instead of silent truncation
- Result field names are frozen (immutable)

#### Relevant Changelog Links:
- [v0.18.4](https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md#v0184-2015-11-13-michael-granger-gedfaeriemudorg)
- [v0.18.3](https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md#v0183-2015-09-03-michael-granger-gedfaeriemudorg)
- [v0.18.2](https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md#v0182-2015-05-14-michael-granger-gedfaeriemudorg)
- [v0.18.1](https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md#v0181-2015-01-05-michael-granger-gedfaeriemudorg)
- [v0.18.0](https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md#v0180-2015-01-01-michael-granger-gedfaeriemudorg)

### Code Changes

For this upgrade, no application code changes were required because:

1. **ActiveRecord Abstraction**: The application uses ActiveRecord as the database interface, which abstracts away direct pg gem usage
2. **No Direct PG API Usage**: No code directly calls `PG::Connection` or `PG::Result` methods
3. **Standard Operations Only**: The application only uses standard database operations (queries, inserts, updates) which are handled by ActiveRecord

### Testing Strategy

To verify the upgrade:

1. **With old behavior** (`K2_DEPENDENCY_UPGRADED_NEXT=false` or unset):
   ```bash
   bundle exec rspec
   ```

2. **With new behavior** (`K2_DEPENDENCY_UPGRADED_NEXT=true`):
   ```bash
   K2_DEPENDENCY_UPGRADED_NEXT=true bundle exec rspec
   ```

3. **Integration testing**: Test full application stack with both configurations

### Rollback Plan

If issues are discovered in production:
1. Set `K2_DEPENDENCY_UPGRADED_NEXT=false` in environment
2. Deploy code with environment variable change
3. Old behavior is immediately restored

### Future Work

When ready to fully migrate to pg 0.18.4:
1. Remove feature flag checks
2. Remove old code paths
3. Set pg version in Gemfile to `gem 'pg', '~> 0.18.4'`

---

## Template for Future Upgrades

When adding new dependency upgrades, copy this template:

### [Gem Name]: [Old Version] → [New Version]

**PR**: [Link]
**Date**: YYYY-MM-DD
**Change Type**: major/minor/patch

#### What Changed
- List key changes
- Breaking changes
- New features used

#### Relevant Changelog Links
- [Version X](link)

#### Code Changes
- Describe what code was modified
- Why changes were necessary
- Which methods/APIs were affected

#### Testing Strategy
- How to test with old behavior
- How to test with new behavior

#### Rollback Plan
- How to revert if needed
