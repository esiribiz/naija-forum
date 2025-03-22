class AddSecurityQuestionRefToSecurityQuestionAttempts < ActiveRecord::Migration[8.0]
  def change
    # Add the column as nullable first to accommodate existing records
    add_reference :security_question_attempts, :security_question, null: true
    
    # Add the foreign key constraint separately
    add_foreign_key :security_question_attempts, :security_questions
    
    # Note: A future migration will be needed to add the NOT NULL constraint
    # after all existing records have valid security_question_id values
  end
end
