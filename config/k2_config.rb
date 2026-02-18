# K2Config module for managing feature flags
# This allows us to deploy the same codebase with different dependency versions
module K2Config
  # Feature flag for dependency upgrades
  # Set K2_DEPENDENCY_UPGRADED_NEXT=true to enable new dependency behavior
  # Set K2_DEPENDENCY_UPGRADED_NEXT=false or leave unset to use old dependency behavior
  def self.dependency_upgraded_next?
    ENV['K2_DEPENDENCY_UPGRADED_NEXT'] == 'true'
  end
end
