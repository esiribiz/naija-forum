require "devise"

module Devise
  module SecurityQuestionable
    # This module exists to satisfy Zeitwerk's expectations
  end

  # Number of security questions that need to be answered
  mattr_accessor :security_question_count
  @@security_question_count = 2

  # Period of time after which security questions expire
  mattr_accessor :security_question_timeout_in
  @@security_question_timeout_in = 3.months

  # Maximum number of security question attempts before locking
  mattr_accessor :security_question_maximum_attempts
  @@security_question_maximum_attempts = 3

  # Time period to lock account after failed security question attempts
  mattr_accessor :security_question_lock_period
  @@security_question_lock_period = 1.hour

  # Configure email notification after security question changes
  mattr_accessor :security_question_email_notification
  @@security_question_email_notification = true

  # Minimum required length for security question answers
  mattr_accessor :security_question_minimum_length
  @@security_question_minimum_length = 4
end

# Load the security_questionable model extension
require "devise/models/security_questionable"
