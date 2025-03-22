class AddEncryptedColumnsToUsers < ActiveRecord::Migration[8.0]
def change
    add_column :users, :encrypted_phone_number, :text
    add_column :users, :encrypted_ssn, :text
    add_column :users, :encrypted_security_token, :text
end
end
