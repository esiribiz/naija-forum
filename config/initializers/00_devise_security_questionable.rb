# frozen_string_literal: true

# This initializer adds security_questionable configuration options to Devise
# It needs to load before the main Devise initializer

require "devise"

module Devise
  # Configure security questionable settings
  mattr_accessor :security_question_count
  @@security_question_count = 1

  mattr_accessor :min_security_question_age
  @@min_security_question_age = 24.hours

  mattr_accessor :max_security_question_attempts
  @@max_security_question_attempts = 3

  mattr_accessor :security_question_lock_strategy
  @@security_question_lock_strategy = :none # Options: :none, :failed_attempts, :time

  mattr_accessor :security_question_unlock_in
  @@security_question_unlock_in = 1.hour

  # Load security_questionable module
  require "devise/models/security_questionable" if defined?(Devise)
end
