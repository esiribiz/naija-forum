FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    # Color is optional as the model has a callback to generate one if not provided
    # Example: color { "#FF5733" }
  end
end

