require 'rails_helper'

RSpec.describe LoginActivity, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:ip_address) }
    it { should validate_presence_of(:user_agent) }
    it { should validate_presence_of(:login_at) }
  end

  describe "scopes" do
    let!(:successful_login) { create(:login_activity, success: true) }
    let!(:failed_login) { create(:login_activity, :failed) }

    it "filters successful logins" do
      expect(LoginActivity.successful).to include(successful_login)
      expect(LoginActivity.successful).not_to include(failed_login)
    end

    it "filters failed logins" do
      expect(LoginActivity.failed).to include(failed_login)
      expect(LoginActivity.failed).not_to include(successful_login)
    end

    it "orders by recent login time" do
      old_login = create(:login_activity, login_at: 2.days.ago)
      new_login = create(:login_activity, login_at: 1.day.ago)

      recent_logins = LoginActivity.where(id: [old_login.id, new_login.id]).recent
      expect(recent_logins.first).to eq(new_login)
      expect(recent_logins.last).to eq(old_login)
    end
  end

  describe ".most_recent_for" do
    let(:user) { create(:user) }

    it "returns the most recent successful login" do
      old_login = create(:login_activity, user: user, login_at: 2.days.ago)
      new_login = create(:login_activity, user: user, login_at: 1.day.ago)

      expect(LoginActivity.most_recent_for(user)).to eq(new_login)
    end

    it "doesn't return failed logins" do
      failed_login = create(:login_activity, :failed, user: user, login_at: Time.current)
      successful_login = create(:login_activity, user: user, login_at: 1.day.ago)

      expect(LoginActivity.most_recent_for(user)).to eq(successful_login)
    end
  end
end
