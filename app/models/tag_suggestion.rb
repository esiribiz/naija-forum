class TagSuggestion < ApplicationRecord
  # Relationships
  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true

  # Validations
  validates :name, presence: true, uniqueness: { scope: :approved, case_sensitive: false }
  validates :category, inclusion: { in: ApprovedTag::CATEGORIES.keys, allow_blank: true }

  # Callbacks
  before_validation :normalize_name
  before_validation :detect_category, if: :category_blank?

  # Scopes
  scope :pending, -> { where(approved: false) }
  scope :approved_suggestions, -> { where(approved: true) }
  scope :by_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }

  def approve!(approved_by_user)
    transaction do
      # Create the approved tag
      approved_tag = ApprovedTag.create!(
        name: name,
        category: category || detect_category_for_name,
        description: description,
        is_active: true,
        is_featured: false
      )

      # Update this suggestion as approved
      update!(
        approved: true,
        approved_at: Time.current,
        approved_by: approved_by_user
      )

      approved_tag
    end
  end

  def reject!
    destroy
  end

  def pending?
    !approved?
  end

  def category_display
    ApprovedTag::CATEGORIES[category] if category.present?
  end

  def suggested_category
    category.presence || detect_category_for_name
  end

  private

  def normalize_name
    self.name = name.to_s.strip.gsub(/\s+/, " ") if name.present?
  end

  def category_blank?
    category.blank?
  end

  def detect_category
    self.category = detect_category_for_name
  end

  def detect_category_for_name
    return unless name.present?

    # Check if it matches any predefined categories
    return "geographic" if ApprovedTag.geographic_tags.include?(name)
    return "professional" if ApprovedTag.professional_tags.include?(name)
    return "country_region" if ApprovedTag.country_region_tags.include?(name)
    return "special_project" if ApprovedTag.special_project_tags.include?(name)

    # Default to thematic for user-generated suggestions
    "thematic"
  end
end
