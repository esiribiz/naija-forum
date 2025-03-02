class AddPublishedToPosts < ActiveRecord::Migration[8.0]
def change
    add_column :posts, :published, :boolean, default: true
    
    # Ensure all existing posts are marked as published
    Post.update_all(published: true) if Post.table_exists?
end
end
