FactoryBot.define do
  factory :login_activity do
    association :user
    ip_address { "192.168.1.#{rand(1..255)}" }
    user_agent { "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/#{rand(80..110)}.0.#{rand(1000..5000)}.#{rand(10..200)} Safari/537.36" }
    login_at { Time.current }
    success { true }
    
    trait :failed do
      success { false }
      failure_reason { "Invalid credentials" }
    end
    
    trait :with_location do
      country { "Nigeria" }
      city { "Lagos" }
      region { "Lagos State" }
    end
  end
end

