class AddLastSecurityQuestionAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_security_question_at, :datetime
  end
end
