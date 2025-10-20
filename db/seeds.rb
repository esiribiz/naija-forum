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



