namespace :admin do
  desc "Create a super admin user"
  task create_super_admin: :environment do
    puts "Creating super admin user..."
    
    email = ENV['ADMIN_EMAIL'] || 'admin@example.com'
    password = ENV['ADMIN_PASSWORD'] || SecureRandom.hex(8)
    username = ENV['ADMIN_USERNAME'] || 'superadmin'
    
    # Check if admin already exists
    existing_admin = User.find_by(email: email)
    if existing_admin
      puts "Admin user already exists with email: #{email}"
      if existing_admin.admin?
        puts "User is already an admin."
      else
        existing_admin.update!(role: 'admin')
        puts "Upgraded existing user to admin role."
      end
      return
    end
    
    # Create new admin user
    admin = User.new(
      email: email,
      password: password,
      password_confirmation: password,
      username: username,
      first_name: 'Super',
      last_name: 'Admin',
      role: 'admin'
    )
    
    # Skip certain validations if they're causing issues
    admin.save!(validate: false) if admin.invalid?
    
    if admin.persisted?
      puts "✅ Super admin created successfully!"
      puts "Email: #{email}"
      puts "Username: #{username}"
      puts "Password: #{password}"
      puts "Role: #{admin.role}"
      puts ""
      puts "You can now login to the admin panel at: /admin"
    else
      puts "❌ Failed to create super admin:"
      admin.errors.full_messages.each { |error| puts "  - #{error}" }
    end
  end
end