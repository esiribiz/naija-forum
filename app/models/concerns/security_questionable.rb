# frozen_string_literal: true

module SecurityQuestionable
  extend ActiveSupport::Concern

  included do
    # Associations
    has_many :security_questions, dependent: :destroy
    has_many :security_question_attempts, dependent: :destroy

    # Validations
    validates :security_questions, length: { minimum: 1, message: "must have at least one security question set" },
                                  if: -> { security_questions_required? }
  end

  # Class methods
  class_methods do
    def security_questions_required?
      true # Override this in the User model if needed
    end

    def max_security_question_attempts
      5  # The maximum number of attempts before locking
    end

    def security_question_attempt_timeout
      1.hour # Time period for rate limiting
    end
  end

  # Instance methods
  def security_questions_required?
    self.class.security_questions_required?
  end

  def add_security_question(question, answer)
    security_questions.create(question: question, answer: answer)
  end

  def update_security_question(id, question, answer)
    security_question = security_questions.find_by(id: id)
    return false unless security_question

    security_question.update(question: question, answer: answer)
  end

  def remove_security_question(id)
    security_question = security_questions.find_by(id: id)
    return false unless security_question

    security_question.destroy
    true
  end

  def verify_security_question(id, answer)
    security_question = security_questions.find_by(id: id)
    return false unless security_question

    # Record the attempt
    attempt = security_question_attempts.create(
      security_question_id: id,
      successful: security_question.correct_answer?(answer)
    )

    # Return the result
    attempt.successful
  end

  def security_question_attempts_exceeded?
    recent_attempts = security_question_attempts
                        .where("created_at > ?", self.class.security_question_attempt_timeout.ago)
                        .where(successful: false)
                        .count

    recent_attempts >= self.class.max_security_question_attempts
  end

  def reset_security_question_attempts
    security_question_attempts.delete_all
  end

  def security_question_attempt_count
    security_question_attempts
      .where("created_at > ?", self.class.security_question_attempt_timeout.ago)
      .where(successful: false)
      .count
  end

  def security_questions_set?
    security_questions.exists?
  end

  def remaining_security_question_attempts
    [0, self.class.max_security_question_attempts - security_question_attempt_count].max
  end
end
