# frozen_string_literal: true

Devise.setup do |config|
# ==> Security Extension
# Configure security extension for devise

# How many passwords to keep in archive
config.password_archiving_count = 5

# Deny old passwords (true, false, number)
config.deny_old_passwords = true

# enable password expiration
config.expire_password_after = 6.months

# Set minimum password length
config.password_length = 12..128

# Security questions configuration removed - not supported by devise-security
end
