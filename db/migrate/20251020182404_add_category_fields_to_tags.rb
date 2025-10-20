class AddCategoryFieldsToTags < ActiveRecord::Migration[8.0]
  def change
    add_column :tags, :category, :string, null: false, default: 'thematic'
    add_column :tags, :is_official, :boolean, null: false, default: false
    add_column :tags, :is_featured, :boolean, null: false, default: false
    
    add_index :tags, :category
    add_index :tags, :is_official
    add_index :tags, :is_featured
  end
end
