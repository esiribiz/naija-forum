class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :bio, :string
    add_column :users, :location, :string
    add_column :users, :website, :string
    add_column :users, :twitter, :string
    add_column :users, :linkedin, :string
    add_column :users, :facebook, :string
  end
end
