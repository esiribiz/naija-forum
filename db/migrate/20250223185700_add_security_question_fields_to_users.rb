class AddSecurityQuestionFieldsToUsers < ActiveRecord::Migration[7.0]
def change
    add_column :users, :security_question_id, :integer
    add_column :users, :security_question_answer, :string

    add_index :users, :security_question_id
    add_foreign_key :users, :security_questions, column: :security_question_id
end
end
