class SecurityQuestionAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :security_question

  # successful - boolean - tracks whether the attempt was successful
end
