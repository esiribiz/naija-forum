class CreateLoginActivities < ActiveRecord::Migration[7.0]
  def change
    create_table :login_activities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address, null: false
      t.string :user_agent, null: false
      t.datetime :login_at, null: false
      t.boolean :success, default: true
      t.string :country
      t.string :city
      t.string :region
      t.text :failure_reason

      t.timestamps
    end
    
    add_index :login_activities, [:user_id, :login_at]
    add_index :login_activities, :ip_address
  end
end

