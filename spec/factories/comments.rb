FactoryBot.define do
  factory :comment do
    association :user
    association :post
    content { "This is a valid comment with enough content to meet validation requirements." }

    trait :reply do
      parent { association :comment }
    end
  end
end

