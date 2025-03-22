FactoryBot.define do
  factory :post do
    association :user
    association :category
    title { "Valid Post Title" }
    body { "This is a valid post body with enough content to pass validation requirements." }
  end
end

