# Feature Flag Pattern for Dependency Upgrades

## Overview

This document describes the pattern used for managing dependency upgrades in this codebase.

## The Problem

When upgrading dependencies (especially major or minor versions), we need to:
1. Test new versions safely in production-like environments
2. Keep the ability to quickly rollback if issues are found
3. Deploy the same codebase with different dependency versions
4. Avoid long-lived feature branches that become merge nightmares

## The Solution: Feature Flag Pattern

We use the `K2Config.dependency_upgraded_next?` feature flag to enable dual code paths.

### How It Works

```ruby
if K2Config.dependency_upgraded_next?
  # New dependency version behavior
  # This code only runs when K2_DEPENDENCY_UPGRADED_NEXT=true
else
  # Old dependency version behavior (default)
  # This is the current production behavior
end
```

### Environment Variable

Set `K2_DEPENDENCY_UPGRADED_NEXT=true` to enable new dependency behavior:

```bash
# Enable new dependency behavior
export K2_DEPENDENCY_UPGRADED_NEXT=true

# Or inline for a single command
K2_DEPENDENCY_UPGRADED_NEXT=true bundle exec rspec
```

Leave it unset or set to `false` for old (current production) behavior:

```bash
# Old behavior (default)
bundle exec rspec

# Or explicitly
K2_DEPENDENCY_UPGRADED_NEXT=false bundle exec rspec
```

## Rules for Adding Code

### 1. Never Touch Old Code Paths

❌ **WRONG:**
```ruby
# Modifying existing behavior
def process_data
  result = calculate_something  # Changed this line - breaks old version!
  result.transform
end
```

✅ **CORRECT:**
```ruby
# Keeping old behavior intact
def process_data
  if K2Config.dependency_upgraded_next?
    # New behavior for upgraded dependencies
    # Explanation: In pg 0.18.x, OID mapping changed to unsigned integers
    # Changelog: https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md#v0180
    result = calculate_something_new_way
  else
    # Old behavior - unchanged
    result = calculate_something
  end
  result.transform
end
```

### 2. Add Explanatory Comments

Always add comments in the `dependency_upgraded_next?` branch explaining:
- What changed in the new dependency version
- Why the change was necessary
- Link to changelog entry

Example:
```ruby
if K2Config.dependency_upgraded_next?
  # pg 0.18.x returns frozen strings for field names
  # We need to dup before modifying
  # Changelog: https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md#v0180
  field_name = result.fields.first.dup
  field_name.upcase!
else
  # pg 0.17.x returns mutable strings
  field_name = result.fields.first
  field_name.upcase!
end
```

### 3. Document in Changelog

Every dependency upgrade must be documented in `docs/dependency-upgrades-changelog.md`:

- What changed in the dependency
- What code was modified
- Links to relevant changelogs
- Testing strategy
- Rollback plan

## Deployment Strategy

### Phase 1: Development & Testing
1. Create PR with feature-flagged code
2. All CI runs with `K2_DEPENDENCY_UPGRADED_NEXT=false` (old behavior)
3. Manually test with `K2_DEPENDENCY_UPGRADED_NEXT=true` (new behavior)
4. Ensure both modes work correctly

### Phase 2: Staging/Canary
1. Deploy code to staging with flag disabled
2. Verify old behavior still works
3. Enable flag in staging: `K2_DEPENDENCY_UPGRADED_NEXT=true`
4. Run full test suite and manual QA
5. Deploy to canary/subset of production with flag enabled

### Phase 3: Production Rollout
1. Deploy code to production with flag disabled (safe, no changes)
2. Monitor metrics and logs
3. Gradually enable flag: `K2_DEPENDENCY_UPGRADED_NEXT=true`
   - Start with small percentage of traffic/servers
   - Increase gradually
   - Watch for errors, performance issues
4. If issues found: immediately set flag to `false` (instant rollback)

### Phase 4: Cleanup
Once new version is stable in production for sufficient time:
1. Remove feature flag checks
2. Remove old code paths
3. Pin dependency version in Gemfile
4. Update documentation

## Testing

### Test Both Modes

Always test both modes in development:

```bash
# Test old behavior (default)
bundle exec rspec

# Test new behavior
K2_DEPENDENCY_UPGRADED_NEXT=true bundle exec rspec

# Test old behavior explicitly
K2_DEPENDENCY_UPGRADED_NEXT=false bundle exec rspec
```

### CI Configuration

Configure CI to test both modes:

```yaml
# .github/workflows/test.yml
jobs:
  test-old:
    env:
      K2_DEPENDENCY_UPGRADED_NEXT: false
    steps:
      - run: bundle exec rspec

  test-new:
    env:
      K2_DEPENDENCY_UPGRADED_NEXT: true
    steps:
      - run: bundle exec rspec
```

## Examples

### Example 1: API Method Change

```ruby
# In a hypothetical service that uses pg directly
class DatabaseQuery
  def get_connection_info
    conn = ActiveRecord::Base.connection.raw_connection
    
    if K2Config.dependency_upgraded_next?
      # pg 0.18.0 added PG::Connection#conninfo method
      # Returns a hash of connection parameters
      # Changelog: https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md#v0180
      conn.conninfo
    else
      # pg 0.17.x doesn't have conninfo method
      # Build info manually from connection parameters
      {
        host: conn.host,
        port: conn.port,
        dbname: conn.db
      }
    end
  end
end
```

### Example 2: Type Handling Change

```ruby
class OidProcessor
  def process_oid(oid)
    if K2Config.dependency_upgraded_next?
      # pg 0.18.0 changed OID mapping from signed to unsigned integers
      # This affects how we validate and compare OIDs
      # Changelog: https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md#v0180
      raise ArgumentError, "Invalid OID" if oid < 0 || oid > 4294967295
      oid.to_i
    else
      # pg 0.17.x used signed integers for OIDs
      raise ArgumentError, "Invalid OID" if oid < -2147483648 || oid > 2147483647
      oid.to_i
    end
  end
end
```

### Example 3: Configuration Changes

```ruby
# config/database.rb
connection_options = {
  adapter: 'postgresql',
  host: 'localhost',
  # ... other options
}

if K2Config.dependency_upgraded_next?
  # pg 0.18.x adds support for new connection options
  # Enable new feature for better performance
  # Changelog: https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md#v0180
  connection_options[:some_new_feature] = true
end

ActiveRecord::Base.establish_connection(connection_options)
```

## Common Pitfalls

### ❌ Don't: Modify Shared State Differently

```ruby
# BAD: Different behavior for shared state
if K2Config.dependency_upgraded_next?
  @cache = NewCache.new
else
  @cache = OldCache.new
end
# Problem: Code that uses @cache might behave unexpectedly
```

### ❌ Don't: Make Breaking Changes Outside the Flag

```ruby
# BAD: Changing method signature
def process(data, new_option = nil)  # Added parameter
  if K2Config.dependency_upgraded_next?
    handle_new_way(data, new_option)
  else
    handle_old_way(data)  # Doesn't use new_option
  end
end
# Problem: Callers need to change even with old behavior
```

### ✅ Do: Keep Interfaces Consistent

```ruby
# GOOD: Same interface, different implementation
def process(data)
  if K2Config.dependency_upgraded_next?
    # New dependency: Changed behavior internally
    handle_new_way(data)
  else
    handle_old_way(data)
  end
end
```

## Benefits

1. **Safe Rollback**: Flip flag to instantly revert to old behavior
2. **Same Codebase**: Deploy once, test both versions
3. **Gradual Rollout**: Enable incrementally in production
4. **Clear Documentation**: All changes are documented with context
5. **Easy Cleanup**: Remove flag and old code when stable

## Questions?

See the [Dependency Upgrades Changelog](dependency-upgrades-changelog.md) for specific upgrade details.
