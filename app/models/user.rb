class User < ApplicationRecord
  # Devise authentication modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one_attached :avatar

  # Validations
  validates :username, presence: true, uniqueness: true
  validates :bio, length: { maximum: 300 } # Limit bio to 300 characters
  validates :website, :twitter, :linkedin, :facebook, format: { with: /\Ahttps?:\/\/.+\z/, message: "must be a valid URL" }, allow_blank: true

  # Optional: Add more custom validations as needed


  def admin?
    role == "admin"
  end
end
