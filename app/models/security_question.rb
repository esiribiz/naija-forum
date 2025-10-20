class SecurityQuestion < ApplicationRecord
  belongs_to :user

  validates :question, presence: true
  validates :answer, presence: true

  before_save :downcase_answer

  # Checks if the provided answer matches the stored answer (case insensitive)
  # @param answer_attempt [String] the answer to check
  # @return [Boolean] true if the answer matches, false otherwise
  def correct_answer?(answer_attempt)
    return false if answer_attempt.blank?
    answer == answer_attempt.downcase
  end

  private

  def downcase_answer
    self.answer = answer.downcase if answer.present?
  end
end
