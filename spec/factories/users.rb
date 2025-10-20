FactoryBot.define do
factory :user do
    email { Faker::Internet.unique.email }
    username do
    # Generate valid username with only letters, numbers, underscores, and dashes
    charset = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    special = ['_', '-']
    length = rand(5..15)
    username = ''
    length.times do |i|
        # Add an underscore or dash occasionally (10% chance)
        username += rand(10) == 0 ? special.sample : charset.sample
    end
    # Ensure the username starts with a letter
    username = ('a'..'z').to_a.sample + username if username =~ /^[^a-zA-Z]/
    # Ensure username is between 3-20 chars
    username = username[0...20]
    username = username.ljust(3, charset.sample) if username.length < 3
    username
    end
    password {
    # Generate complex password with:
    # - At least 12 characters
    # - At least one uppercase letter
    # - At least one lowercase letter
    # - At least one number
    # - At least one special character

    # Explicitly include required character types
    uppercase = ('A'..'Z').to_a.sample(2).join
    lowercase = ('a'..'z').to_a.sample(2).join
    number = rand(100..999).to_s
    symbol = ['!', '@', '#', '$', '%', '^', '&', '*'].sample(2).join

    # Create a base with all required elements
    base = uppercase + lowercase + number + symbol

    # Add random characters if needed to reach minimum length
    # Make sure the password is at least 12 characters long
    if base.length < 12
        extra_chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
        extra = extra_chars.sample(12 - base.length).join
        base += extra
    end

    # Shuffle the characters to avoid predictable patterns
    # and ensure characters are randomly distributed
    base.chars.shuffle.join
    }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    # Add security questions to all users
    # Extract common questions to avoid duplication
    transient do
      security_question_list do
        [
          "What was your childhood nickname?",
          "What is the name of your first pet?",
          "In what city or town was your first job?"
        ]
      end
    end

    # Add security questions when building a user (non-persisted)
    after(:build) do |user, evaluator|
      evaluator.security_question_list.each do |question|
        user.security_questions << build(:security_question,
          user: user,
          question: question,
          answer: Faker::Lorem.word
        )
      end
    end

    # Add security questions when creating a user (persisted to database)
    after(:create) do |user, evaluator|
      # Only create security questions if they weren't already created
      if user.security_questions.empty?
        evaluator.security_question_list.each do |question|
          create(:security_question, user: user, question: question, answer: Faker::Lorem.word)
        end
      end
    end

    # Basic traits for user variations
    trait :with_posts do
    after(:create) do |user|
        create_list(:post, 3, user: user)
    end
    end

    trait :with_comments do
    after(:create) do |user|
        create_list(:comment, 3, user: user)
    end
    end

    trait :with_bio do
    bio { Faker::Lorem.paragraph(sentence_count: 2) }
    end

    trait :with_website do
    website { Faker::Internet.url }
    end

    trait :admin do
    role { "admin" }
    after(:create) do |user|
        # Add any admin-specific setup here if needed
    end
    end
    # Trait combinations
    trait :complete_profile do
    with_bio
    with_website
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    end

    # Invalid user traits for testing validations
    trait :invalid_email do
    email { "invalid_email" }
    end

    trait :invalid_username do
    username { "a" } # Too short username
    end
end
end
