class AddSecurityQuestionsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :security_question_1, :string
    add_column :users, :security_question_2, :string
    add_column :users, :security_question_3, :string
    add_column :users, :security_answer_1, :string
    add_index :users, :security_answer_1
    add_column :users, :security_answer_2, :string
    add_index :users, :security_answer_2
    add_column :users, :security_answer_3, :string
    add_index :users, :security_answer_3
    add_column :users, :security_questions_completed_at, :datetime
    add_column :users, :security_question_failed_attempts, :integer
  end
end
