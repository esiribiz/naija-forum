require 'rails_helper'

RSpec.describe User, type: :model do
describe "with password_archivable module" do
    let(:user) { create(:user, password: "Initial_P@ssw0rd!") }

    it "should include the password_archivable module" do
    expect(User.devise_modules).to include(:password_archivable)
    end

    it "should archive old passwords when password is changed" do
    # Change password
    old_password = user.password
    user.password = "N3w_S3cure_P@ssw0rd!"
    user.password_confirmation = "N3w_S3cure_P@ssw0rd!"
    user.save

    # Verify the old password is archived
    expect(user.old_passwords.count).to eq(1)
    end

    it "should not allow reusing the current password" do
    current_password = user.password
    user.password = current_password
    user.password_confirmation = current_password

    expect(user).not_to be_valid
    expect(user.errors[:password]).to include("was used previously")
    end

    it "should not allow reusing recent passwords" do
    # Change password multiple times
    passwords = ["P@ssw0rd_One!", "P@ssw0rd_Two!", "P@ssw0rd_Three!", "P@ssw0rd_Four!"]

    passwords.each do |new_password|
        user.password = new_password
        user.password_confirmation = new_password
        user.save
    end

    # Try to reuse the first password
    user.password = passwords.first
    user.password_confirmation = passwords.first

    expect(user).not_to be_valid
    expect(user.errors[:password]).to include("was used previously")
    end

    it "should only keep the configured number of old passwords" do
    # Assuming config.password_archiving_count = 5 in initializers
    max_count = Devise.password_archiving_count

    # Change password more times than the max count
    (max_count + 2).times do |i|
        user.password = "D1ffer3nt_P@ss_#{i}!"
        user.password_confirmation = "D1ffer3nt_P@ss_#{i}!"
        user.save
    end

    # Verify only the configured number of old passwords are kept
    expect(user.old_passwords.count).to eq(max_count)
    end
end
end
