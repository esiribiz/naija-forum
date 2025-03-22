class Category < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_one_attached :image # ✅ Active Storage for image uploads

  before_validation :set_random_color, if: -> { color.blank? }
  before_save :set_image_prefix, if: -> { image.blank? && name.present? }

  validates :name, presence: true, uniqueness: true
  validates :color, presence: true

  private

  # ✅ Generate a random color (if none is provided)
  def set_random_color
    self.color = format("#%06x", rand(0..0xFFFFFF))
  end

  # ✅ Generate an image prefix if no image is attached
  def set_image_prefix
    if image.blank?
      initials = generate_prefix
      # You can store initials somewhere or create a placeholder image dynamically
    end
  end

  # ✅ Extracts initials for image prefix
  def generate_prefix
    words = name.split
    initials = words.length > 1 ? words[0][0] + words[1][0] : words[0][0..1]
    initials.upcase
  end
end
