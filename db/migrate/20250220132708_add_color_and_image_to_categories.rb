class AddColorAndImageToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :color, :string
    add_column :categories, :image, :string
  end
end
