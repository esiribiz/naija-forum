# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
User.create!(email: "esiribiz@gmail.com", password: "1234567", username: "AdminUser")
Category.create!(name: "General Discussion", description: "Talk about anything here.")
Category.create!(name: "Tech", description: "Discuss the latest in technology.")
Tag.create([ { name: "Ruby" }, { name: "Rails" }, { name: "Flutter" }, { name: "JavaScript" } ])
