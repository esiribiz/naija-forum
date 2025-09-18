class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add index for posts ordered by creation date (for latest posts)
    add_index :posts, :created_at, name: 'index_posts_on_created_at' unless index_exists?(:posts, :created_at)
    
    # Add index for comments ordered by creation date (for recent comments)
    add_index :comments, :created_at, name: 'index_comments_on_created_at' unless index_exists?(:comments, :created_at)
    
    # Add index for users by role (for admin filtering)
    add_index :users, :role, name: 'index_users_on_role' unless index_exists?(:users, :role)
    
    # Add composite index for posts with user and category for efficient includes
    add_index :posts, [:user_id, :category_id, :created_at], name: 'index_posts_on_user_category_created' unless index_exists?(:posts, [:user_id, :category_id, :created_at])
    
    # Add index for published posts (if you plan to have draft posts)
    add_index :posts, [:published, :created_at], name: 'index_posts_on_published_created' unless index_exists?(:posts, [:published, :created_at])
    
    # Add index for user's last activity for performance  
    add_index :users, :last_active_at, name: 'index_users_on_last_active_at' unless index_exists?(:users, :last_active_at)
  end
end
