# K2Config - Configuration module for feature flags
#
# This module provides feature flags to control behavior across different
# dependency versions without modifying the old code paths.
module K2Config
  # Feature flag for dependency upgrades
  #
  # Returns true when testing new dependency versions, false for production/current versions
  # Set via environment variable: DEPENDENCY_UPGRADED_NEXT=true
  #
  # Usage:
  #   if K2Config.dependency_upgraded_next?
  #     # New code for upgraded dependencies
  #   else
  #     # Original code - DO NOT MODIFY
  #   end
  def self.dependency_upgraded_next?
    ENV['DEPENDENCY_UPGRADED_NEXT'] == 'true'
  end
end
