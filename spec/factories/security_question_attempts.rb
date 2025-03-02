FactoryBot.define do
  factory :security_question_attempt do
    user { nil }
    question { "MyString" }
    answer { "MyString" }
    successful { false }
  end
end
