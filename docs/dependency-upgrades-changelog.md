# Dependency Upgrades Changelog

This document tracks changes made to support gem dependency upgrades using the `K2Config.dependency_upgraded_next?` feature flag pattern.

## Format

Each entry should include:
- **Date**: When the change was made
- **Gem(s)**: Which gem(s) were upgraded (with version numbers)
- **Changes**: What code changes were necessary
- **Reason**: Why the changes were needed
- **Links**: Links to relevant changelogs or documentation

---

## Example Entry

### 2026-02-18 - ActiveRecord 7.1 → 7.2

**Gems upgraded**:
- `activerecord` 7.1.0 → 7.2.0

**Changes made**:
- Updated session serialization in `config/environment.rb`
  - Added `serializer: :json_marshal` option when `dependency_upgraded_next?` is true
- Updated database connection in `config/database.rb`
  - Replaced deprecated `#tables` with `#data_sources` for new version

**Reason**:
- Rails 7.2 changed default session serialization from :marshal to :json_marshal
- ActiveRecord 7.2 deprecated `#tables` in favor of `#data_sources`

**Links**:
- [Rails 7.2 Release Notes](https://guides.rubyonrails.org/7_2_release_notes.html)
- [ActiveRecord CHANGELOG](https://github.com/rails/rails/blob/7-2-stable/activerecord/CHANGELOG.md)

---

## Upgrade History

_Entries will be added here as upgrades are implemented_
