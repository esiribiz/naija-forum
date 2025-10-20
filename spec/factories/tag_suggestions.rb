FactoryBot.define do
  factory :tag_suggestion do
    name { "MyString" }
    category { "MyString" }
    description { "MyText" }
    user { nil }
    approved { false }
  end
end
