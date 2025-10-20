require 'rails_helper'

RSpec.describe "Admin::TagSuggestions", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/admin/tag_suggestions/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/admin/tag_suggestions/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /approve" do
    it "returns http success" do
      get "/admin/tag_suggestions/approve"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /reject" do
    it "returns http success" do
      get "/admin/tag_suggestions/reject"
      expect(response).to have_http_status(:success)
    end
  end

end
