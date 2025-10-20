class CreateApprovedTags < ActiveRecord::Migration[8.0]
  def change
    create_table :approved_tags do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.text :description
      t.boolean :is_active, null: false, default: true
      t.boolean :is_featured, null: false, default: false

      t.timestamps
    end

    add_index :approved_tags, :name, unique: true
    add_index :approved_tags, :category
    add_index :approved_tags, :is_active
    add_index :approved_tags, :is_featured
    add_index :approved_tags, [:category, :is_active]
  end
end
