# frozen_string_literal: true

# Load the security_questionable module
require "devise/models/security_questionable"

# Add the module to Devise
Devise.add_module :security_questionable, model: true
