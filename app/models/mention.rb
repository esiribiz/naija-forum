class Mention < ApplicationRecord
  belongs_to :mentionable, polymorphic: true
  belongs_to :user

  validates :user, presence: true
  validates :mentionable, presence: true
  
  # Prevent duplicate mentions of the same user in the same mentionable object
  validates :user_id, uniqueness: { scope: [:mentionable_id, :mentionable_type] }
end

