class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :notifiable, polymorphic: true, null: false
      t.references :actor, foreign_key: { to_table: :users }, null: true
      t.string :action, null: false
      t.boolean :read, null: false, default: false

      t.timestamps
    end
    
    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :notifications, [:user_id, :read]
  end
end

