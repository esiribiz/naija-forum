require 'rails_helper'

RSpec.describe User, type: :model do
describe "with security_questionable module" do
    it "includes the security_questionable module" do
    expect(User.included_modules).to include(Devise::Models::SecurityQuestionable)
    end
end
end
