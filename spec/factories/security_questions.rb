FactoryBot.define do
  factory :security_question do
    question { "What was your childhood nickname?" }
    answer { "Buddy" }

    trait :with_user do
      association :user
    end

    factory :custom_security_question do
      question { "What is your favorite color?" }
      answer { "Blue" }
    end
  end
end
