# Feature Flag Pattern for Dependency Upgrades

This document describes the `K2Config.dependency_upgraded_next?` pattern used in this repository to safely manage dependency upgrades.

## Overview

The `dependency_upgraded_next?` feature flag allows us to:
- Deploy the **same codebase** with different dependency versions
- Test new dependency versions without breaking production
- Maintain backward compatibility during upgrades
- Gradually roll out dependency changes

## The Problem

When upgrading dependencies (especially major versions), we often face:
- **Breaking API changes**: Methods are renamed, removed, or have different signatures
- **Behavior changes**: Default values or behaviors change
- **Configuration changes**: New required options or deprecated settings

Directly updating code to work with new versions would break production, which runs on current versions.

## The Solution: Feature Flag Pattern

Use `K2Config.dependency_upgraded_next?` to conditionally execute code based on dependency version:

```ruby
if K2Config.dependency_upgraded_next?
  # Code for NEW dependency versions
  # Safe to use new APIs, new behavior
  new_api_call(new_option: true)
else
  # Code for CURRENT dependency versions
  # NEVER modify this - production depends on it!
  old_api_call
end
```

## Core Rules

### Rule 1: Never Touch Old Code Paths ⛔

The `else` branch (or code outside the flag) represents **production behavior**.

**Never**:
- Modify logic in the `else` branch
- Remove the `else` branch
- Change behavior of unflagged code

**Why**: Production runs with `dependency_upgraded_next? == false`. Any changes to old paths could break production.

### Rule 2: All New Behavior Behind Flag ✅

Any code changes needed for upgraded dependencies **must** be behind the flag.

**Examples**:
- New API method calls
- Changed method signatures
- New configuration options
- Callback changes
- Database query adjustments

### Rule 3: Document Everything 📝

Inside each `dependency_upgraded_next?` block, add:

1. **What changed**: Brief description of the change
2. **Why**: Reason for the change (what broke, what's deprecated)
3. **Link**: URL to changelog, release notes, or documentation

**Example**:
```ruby
if K2Config.dependency_upgraded_next?
  # Sinatra 4.0 requires 64+ character session secrets for security
  # https://github.com/sinatra/sinatra/blob/v4.0.0/CHANGELOG.md#security
  set :session_secret, ENV.fetch('SESSION_SECRET', SecureRandom.hex(32))
else
  set :session_secret, ENV.fetch('SESSION_SECRET', 'dev-secret')
end
```

## Usage

### Setting the Flag

The flag is controlled via environment variable:

```bash
# Test with new dependencies
DEPENDENCY_UPGRADED_NEXT=true bundle exec rspec

# Run with current dependencies (default)
bundle exec rspec
```

### In CI

CI should run tests in **both modes**:
- `DEPENDENCY_UPGRADED_NEXT=false` (or unset) - Verify old code still works
- `DEPENDENCY_UPGRADED_NEXT=true` - Verify new code works

This ensures neither code path breaks.

## Examples

### Example 1: Method Renamed

**Scenario**: ActiveRecord renamed `#tables` to `#data_sources`

```ruby
def list_tables
  if K2Config.dependency_upgraded_next?
    # ActiveRecord 7.2+ renamed tables to data_sources
    # https://github.com/rails/rails/blob/7-2-stable/activerecord/CHANGELOG.md
    ActiveRecord::Base.connection.data_sources
  else
    ActiveRecord::Base.connection.tables
  end
end
```

### Example 2: New Required Option

**Scenario**: New version requires an option that didn't exist before

```ruby
def configure_cache
  if K2Config.dependency_upgraded_next?
    # Rails 7.2 requires explicit cache_format_version
    # https://guides.rubyonrails.org/7_2_release_notes.html#active-support
    config.cache_store = :memory_store, { cache_format_version: 7.2 }
  else
    config.cache_store = :memory_store
  end
end
```

### Example 3: Behavior Change

**Scenario**: Default behavior changed, need to maintain old behavior

```ruby
def save_session(data)
  if K2Config.dependency_upgraded_next?
    # Rack 3.0 changed session serialization default from Marshal to JSON
    # We use JSON for better security and compatibility
    # https://github.com/rack/rack/blob/3.0.0/CHANGELOG.md
    session_store.save(data, serializer: :json)
  else
    # Rack 2.x uses Marshal by default
    session_store.save(data)
  end
end
```

## Workflow for Implementing Upgrades

1. **Identify breaking changes**
   - Check gem changelogs between versions
   - Look for deprecation warnings
   - Run tests and note failures

2. **Add feature flag branches**
   - Wrap new code in `if K2Config.dependency_upgraded_next?`
   - Keep old code in `else` branch (unchanged!)
   - Add documentation comments

3. **Test both paths**
   ```bash
   # Test old path
   bundle exec rspec
   
   # Test new path
   DEPENDENCY_UPGRADED_NEXT=true bundle exec rspec
   ```

4. **Update changelog**
   - Document in `docs/dependency-upgrades-changelog.md`
   - Include gem versions, changes made, and reasoning

5. **Open draft PR**
   - Start as draft while implementing
   - Convert to ready when both test suites pass

6. **CI verification**
   - CI runs both test modes
   - Merge only when both pass

## Anti-Patterns to Avoid

### ❌ Don't: Modify old code

```ruby
# BAD: This breaks production!
def process_data
  if K2Config.dependency_upgraded_next?
    new_api_method(secure: true)  # New behavior
  else
    old_api_method(insecure: true)  # CHANGED - breaks production!
  end
end
```

### ✅ Do: Keep old code unchanged

```ruby
# GOOD: Old code unchanged
def process_data
  if K2Config.dependency_upgraded_next?
    new_api_method(secure: true)
  else
    old_api_method  # Unchanged from original
  end
end
```

### ❌ Don't: Skip documentation

```ruby
# BAD: No explanation
if K2Config.dependency_upgraded_next?
  new_method
else
  old_method
end
```

### ✅ Do: Document thoroughly

```ruby
# GOOD: Clear documentation
if K2Config.dependency_upgraded_next?
  # Rails 7.2 renamed old_method to new_method for clarity
  # https://github.com/rails/rails/blob/7-2-stable/CHANGELOG.md
  new_method
else
  old_method
end
```

### ❌ Don't: Use flag for non-upgrade changes

```ruby
# BAD: This flag is only for dependency upgrades!
if K2Config.dependency_upgraded_next?
  enable_new_feature  # This is a feature flag, not a dependency upgrade
end
```

### ✅ Do: Use only for dependency upgrades

```ruby
# GOOD: Only for dependency-related changes
if K2Config.dependency_upgraded_next?
  # ActiveRecord 7.2 requires this new validation format
  # https://github.com/rails/rails/blob/7-2-stable/activerecord/CHANGELOG.md
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
else
  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\z/ }
end
```

## Benefits of This Pattern

1. **Safety**: Production code never changes during upgrades
2. **Testability**: Both old and new paths can be tested
3. **Gradual rollout**: Can test in staging before production
4. **Easy rollback**: Just flip the flag back
5. **Clear intent**: Code explicitly shows what changed and why
6. **Documentation**: Changes are documented at point of use

## Removing the Flag (Eventually)

Once new dependencies are fully deployed and stable:

1. Verify the new path works in all environments
2. Remove the `else` branch and the flag check
3. Keep only the new code
4. Document removal in changelog

**Important**: Only remove the flag after new dependencies are the **only** dependencies in use everywhere.
