class CreateSecurityQuestionAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :security_question_attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :question
      t.string :answer
      t.boolean :successful

      t.timestamps
    end
  end
end
