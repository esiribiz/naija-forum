class ApprovedTag < ApplicationRecord
  # Relationships
  has_many :tags, foreign_key: :name, primary_key: :name
  has_many :posts, through: :tags

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :category, presence: true, inclusion: { in: %w[geographic professional thematic country_region special_project] }

  # Callbacks
  before_validation :normalize_name

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :featured, -> { where(is_featured: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :search_by_name, ->(query) { where("LOWER(name) LIKE ?", "%#{query.downcase}%") }

  # Tag categories - same as Tag model for consistency
  CATEGORIES = {
    "geographic" => "Geographic (Nigerian States)",
    "professional" => "Professional & Thematic",
    "thematic" => "Topics & Interests",
    "country_region" => "Country/Region (Diaspora)",
    "special_project" => "Special Projects & Movements"
  }.freeze

  def self.geographic_tags
    %w[
      Abia Abuja Adamawa AkwaIbom Anambra Bauchi Bayelsa Benue Borno CrossRiver
      Delta Ebonyi Edo Ekiti Enugu Gombe Imo Jigawa Kaduna Kano Katsina Kebbi
      Kogi Kwara Lagos Nasarawa Niger Ogun Ondo Osun Oyo Plateau Rivers Sokoto
      Taraba Yobe Zamfara
    ]
  end

  def self.professional_tags
    %w[
      Technology Education Health Business Infrastructure Politics Economy
      Governance Startups Innovation Agriculture Energy Finance Science Culture
      DiasporaLife Opportunities Policy Migration Leadership SocialImpact
      YouthEmpowerment WomenInTech Research Volunteerism
    ]
  end

  def self.country_region_tags
    %w[
      USA UK Canada Germany France Finland Sweden Norway Denmark Netherlands
      Italy Spain UAE SouthAfrica Australia Japan
    ]
  end

  def self.special_project_tags
    %w[
      BuildNaija DiasporaInvest Mentorship NaijaTech CleanEnergy ThinkNaija
      ReturnHome NaijaRising
    ]
  end

  def category_display
    CATEGORIES[category]
  end

  def badge_color
    case category
    when "geographic"
      "bg-blue-100 text-blue-800"
    when "professional", "thematic"
      "bg-green-100 text-green-800"
    when "country_region"
      "bg-purple-100 text-purple-800"
    when "special_project"
      "bg-yellow-100 text-yellow-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def toggle_active!
    update!(is_active: !is_active?)
  end

  def toggle_featured!
    update!(is_featured: !is_featured?)
  end

  private

  def normalize_name
    self.name = name.to_s.strip.gsub(/\s+/, " ") if name.present?
  end
end
