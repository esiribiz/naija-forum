# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#User.create!(email: "esiribizz@gmail.com", password: "6319_Destination", username: "TestUser")
puts "Seeding admin account for NaijaGlobalNet..."

admin_email = "admin@naijaglobalnet.com"
admin_username = "naijaglobal_admin"

# Try to find the existing user by email or username
admin = User.find_by(email: admin_email) || User.find_by(username: admin_username)

if admin
  puts "⚙️ Admin already exists. Updating attributes..."
  admin.update!(
    role: "admin",
    first_name: "NaijaGlobal",
    last_name: "Admin",
    accepted_rules_at: Time.current
  )
else
  puts "🧱 Creating new admin account..."
  admin = User.create!(
    email: admin_email,
    username: admin_username,
    first_name: "NaijaGlobal",
    last_name: "Admin",
    role: "admin",
    password: "StrongPassword123!",
    password_confirmation: "StrongPassword123!",
    accepted_rules_at: Time.current
  )
end

puts "✅ Admin setup complete!"
puts "Email: #{admin.email}"
puts "Password: StrongPassword123!"
puts "Role: #{admin.role}"

# Seed comprehensive tag system
puts "🏷️ Seeding comprehensive tag system..."

# Geographic tags (Nigerian states)
geographic_tags = [
  'Abia', 'Abuja', 'Adamawa', 'AkwaIbom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue', 'Borno', 'CrossRiver',
  'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi',
  'Kogi', 'Kwara', 'Lagos', 'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers', 'Sokoto',
  'Taraba', 'Yobe', 'Zamfara'
]

geographic_tags.each do |tag_name|
  tag = Tag.find_or_create_by(name: tag_name) do |t|
    t.category = 'geographic'
    t.is_official = true
    t.description = "Discussions related to #{tag_name} state/region"
  end
  tag.update!(category: 'geographic', is_official: true) unless tag.category == 'geographic'
end

# Professional & thematic tags
professional_tags = [
  'Technology', 'Education', 'Health', 'Business', 'Infrastructure', 'Politics', 'Economy',
  'Governance', 'Startups', 'Innovation', 'Agriculture', 'Energy', 'Finance', 'Science', 'Culture',
  'DiasporaLife', 'Opportunities', 'Policy', 'Migration', 'Leadership', 'SocialImpact',
  'YouthEmpowerment', 'WomenInTech', 'Research', 'Volunteerism'
]

professional_tags.each do |tag_name|
  tag = Tag.find_or_create_by(name: tag_name) do |t|
    t.category = 'professional'
    t.is_official = true
    t.description = case tag_name
                   when 'Technology' then 'Tech innovation, software development, digital transformation'
                   when 'Education' then 'Educational systems, learning, academic development'
                   when 'Health' then 'Healthcare, medical innovation, public health'
                   when 'Business' then 'Entrepreneurship, commerce, trade opportunities'
                   when 'Infrastructure' then 'Transportation, utilities, urban development'
                   when 'DiasporaLife' then 'Life experiences of Nigerians abroad'
                   when 'YouthEmpowerment' then 'Youth development and empowerment initiatives'
                   when 'WomenInTech' then 'Women in technology and innovation'
                   else "Professional discussions about #{tag_name.downcase}"
                   end
  end
  tag.update!(category: 'professional', is_official: true) unless tag.category == 'professional'
end

# Country/Region tags for diaspora
country_tags = [
  'USA', 'UK', 'Canada', 'Germany', 'France', 'Finland', 'Sweden', 'Norway', 'Denmark', 'Netherlands',
  'Italy', 'Spain', 'UAE', 'SouthAfrica', 'Australia', 'Japan'
]

country_tags.each do |tag_name|
  tag = Tag.find_or_create_by(name: tag_name) do |t|
    t.category = 'country_region'
    t.is_official = true
    t.description = "Nigerian diaspora community in #{tag_name}"
  end
  tag.update!(category: 'country_region', is_official: true) unless tag.category == 'country_region'
end

# Special project tags
special_project_tags = [
  { name: 'BuildNaija', description: 'Nation-building initiatives and development projects' },
  { name: 'DiasporaInvest', description: 'Investment opportunities and diaspora funding' },
  { name: 'Mentorship', description: 'Mentoring programs and knowledge sharing' },
  { name: 'NaijaTech', description: 'Nigerian technology ecosystem and innovation' },
  { name: 'CleanEnergy', description: 'Renewable energy and sustainable development' },
  { name: 'ThinkNaija', description: 'Policy discussions and strategic thinking' },
  { name: 'ReturnHome', description: 'Reverse migration and coming back to Nigeria' },
  { name: 'NaijaRising', description: 'Celebrating Nigerian achievements and progress' }
]

special_project_tags.each do |tag_data|
  tag = Tag.find_or_create_by(name: tag_data[:name]) do |t|
    t.category = 'special_project'
    t.is_official = true
    t.is_featured = true
    t.description = tag_data[:description]
  end
  tag.update!(
    category: 'special_project', 
    is_official: true, 
    is_featured: true,
    description: tag_data[:description]
  ) unless tag.category == 'special_project'
end

puts "✅ Tag system seeded successfully!"
puts "📊 Created tags:"
puts "   🌍 Geographic: #{Tag.by_category('geographic').count}"
puts "   💼 Professional: #{Tag.by_category('professional').count}"
puts "   🌎 Country/Region: #{Tag.by_category('country_region').count}"
puts "   🚀 Special Projects: #{Tag.by_category('special_project').count}"
puts "   ⭐ Featured tags: #{Tag.featured.count}"

