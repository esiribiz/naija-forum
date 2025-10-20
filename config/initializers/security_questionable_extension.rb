# Ensure our extension to Devise::Models::SecurityQuestionable is loaded
# This initializer ensures that our custom behaviors for security questions
# are properly applied when the application starts

require "devise/models/security_questionable_extension" if defined?(Devise::Models::SecurityQuestionable)

Rails.application.config.to_prepare do
  # Patch the SecurityQuestionable module if it exists
  if defined?(Devise::Models::SecurityQuestionable)
    Devise::Models::SecurityQuestionable.prepend(Devise::Models::SecurityQuestionableExtension)
  end
end
