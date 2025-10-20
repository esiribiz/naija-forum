class RemoveUserEncryptionColumns < ActiveRecord::Migration[8.0]
def change
    # Remove encryption-related columns
    remove_column :users, :encrypted_phone_number, :text
    remove_column :users, :encrypted_ssn, :text
    remove_column :users, :encrypted_security_token, :text

    # Remove blind index columns and their indexes
    remove_index :users, :email_bidx if index_exists?(:users, :email_bidx)
    remove_column :users, :email_bidx, :string
end
end
