class CreateTagSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :tag_suggestions do |t|
      t.string :name, null: false
      t.string :category
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.boolean :approved, null: false, default: false
      t.timestamp :approved_at
      t.references :approved_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tag_suggestions, :name
    add_index :tag_suggestions, :category
    add_index :tag_suggestions, :approved
    add_index :tag_suggestions, [:user_id, :approved]
    add_index :tag_suggestions, [:name, :approved], unique: true
  end
end
