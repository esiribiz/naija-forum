# frozen_string_literal: true

class DeviseCreateSecurityQuestionables < ActiveRecord::Migration[8.0]
def change
    create_table :security_questions do |t|
    t.references :user, null: false, foreign_key: true
    t.string :question, null: false
    t.string :answer, null: false
    t.timestamps
    end
    end
end
