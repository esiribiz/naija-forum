FactoryBot.define do
  factory :approved_tag do
    name { "MyString" }
    category { "MyString" }
    description { "MyText" }
    is_active { false }
    is_featured { false }
  end
end
