# frozen_string_literal: true

module Devise
  module Models
    # This module extends the SecurityQuestionable module to patch the validation
    # behavior so that security questions are entirely optional for both new and
    # existing users. Users can create accounts and update profiles without
    # providing security questions.
    module SecurityQuestionableExtension
      # Override the validate_security_questions_answered method to only validate
      # Override the validate_security_questions_answered method to make security questions
      # entirely optional. Only validate format and completeness if questions are provided.
      def validate_security_questions_answered
        # Skip all validation if no security questions are being updated
        return unless security_questions.any? { |q| q.changed? || q.new_record? }
        
        # Only validate the format of security questions if they're provided
        # No minimum number of questions is required
        security_questions.each do |sq|
          next if sq.marked_for_destruction?
          
          if sq.question.blank?
            sq.errors.add(:question, :blank)
            errors.add(:security_questions, "can't have blank questions")
          end
          
          if sq.answer.blank?
            sq.errors.add(:answer, :blank)
            errors.add(:security_questions, "can't have blank answers")
          end
        end
      end
      # Override the security_questions_required? method to always return false
      # This makes security questions optional in all contexts
      def security_questions_required?
        false
      end
      
      # Override the validate_security_questions method to be a no-op
      # This ensures security questions are never required
      def validate_security_questions
        # No validation needed as security questions are optional
      end
    end
  end
end

# Ensure the original module is loaded first
require 'devise/models/security_questionable'

# Apply the extension by prepending to the original module
Devise::Models::SecurityQuestionable.prepend Devise::Models::SecurityQuestionableExtension
