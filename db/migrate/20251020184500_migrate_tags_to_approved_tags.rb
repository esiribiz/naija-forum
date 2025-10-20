class MigrateTagsToApprovedTags < ActiveRecord::Migration[8.0]
  def up
    # Populate ApprovedTags from existing Tag data
    puts "Migrating existing tags to approved tag system..."
    
    # Geographic tags (Nigerian states)
    geographic_tags = [
      'Abia', 'Abuja', 'Adamawa', 'AkwaIbom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue', 'Borno', 'CrossRiver',
      'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi',
      'Kogi', 'Kwara', 'Lagos', 'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers', 'Sokoto',
      'Taraba', 'Yobe', 'Zamfara'
    ]

    # Professional & thematic tags
    professional_tags = [
      'Technology', 'Education', 'Health', 'Business', 'Infrastructure', 'Politics', 'Economy',
      'Governance', 'Startups', 'Innovation', 'Agriculture', 'Energy', 'Finance', 'Science', 'Culture',
      'DiasporaLife', 'Opportunities', 'Policy', 'Migration', 'Leadership', 'SocialImpact',
      'YouthEmpowerment', 'WomenInTech', 'Research', 'Volunteerism'
    ]

    # Country/Region tags for diaspora
    country_tags = [
      'USA', 'UK', 'Canada', 'Germany', 'France', 'Finland', 'Sweden', 'Norway', 'Denmark', 'Netherlands',
      'Italy', 'Spain', 'UAE', 'SouthAfrica', 'Australia', 'Japan'
    ]

    # Special project tags
    special_project_data = [
      { name: 'BuildNaija', description: 'Nation-building initiatives and development projects' },
      { name: 'DiasporaInvest', description: 'Investment opportunities and diaspora funding' },
      { name: 'Mentorship', description: 'Mentoring programs and knowledge sharing' },
      { name: 'NaijaTech', description: 'Nigerian technology ecosystem and innovation' },
      { name: 'CleanEnergy', description: 'Renewable energy and sustainable development' },
      { name: 'ThinkNaija', description: 'Policy discussions and strategic thinking' },
      { name: 'ReturnHome', description: 'Reverse migration and coming back to Nigeria' },
      { name: 'NaijaRising', description: 'Celebrating Nigerian achievements and progress' }
    ]

    # Migrate existing tags first
    existing_tags = execute("SELECT name, category, description, is_official FROM tags").to_a
    
    existing_tags.each do |tag_data|
      name = tag_data['name']
      category = tag_data['category'] || 'thematic'
      description = tag_data['description']
      is_official = tag_data['is_official']
      
      # Skip if already exists
      next if execute("SELECT COUNT(*) FROM approved_tags WHERE LOWER(name) = '#{name.downcase}'").first['count'] > 0
      
      execute <<-SQL
        INSERT INTO approved_tags (name, category, description, is_active, is_featured, created_at, updated_at)
        VALUES ('#{name}', '#{category}', #{description ? "'#{description}'" : 'NULL'}, #{is_official || true}, #{is_official && ['BuildNaija', 'DiasporaInvest', 'NaijaTech', 'CleanEnergy', 'ThinkNaija', 'ReturnHome', 'NaijaRising'].include?(name)}, NOW(), NOW())
      SQL
    end

    # Create geographic tags
    geographic_tags.each do |tag_name|
      next if execute("SELECT COUNT(*) FROM approved_tags WHERE LOWER(name) = '#{tag_name.downcase}'").first['count'] > 0
      
      execute <<-SQL
        INSERT INTO approved_tags (name, category, description, is_active, is_featured, created_at, updated_at)
        VALUES ('#{tag_name}', 'geographic', 'Discussions related to #{tag_name} state/region', true, false, NOW(), NOW())
      SQL
    end

    # Create professional tags
    professional_tags.each do |tag_name|
      next if execute("SELECT COUNT(*) FROM approved_tags WHERE LOWER(name) = '#{tag_name.downcase}'").first['count'] > 0
      
      description = case tag_name
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
      
      execute <<-SQL
        INSERT INTO approved_tags (name, category, description, is_active, is_featured, created_at, updated_at)
        VALUES ('#{tag_name}', 'professional', '#{description}', true, false, NOW(), NOW())
      SQL
    end

    # Create country tags
    country_tags.each do |tag_name|
      next if execute("SELECT COUNT(*) FROM approved_tags WHERE LOWER(name) = '#{tag_name.downcase}'").first['count'] > 0
      
      execute <<-SQL
        INSERT INTO approved_tags (name, category, description, is_active, is_featured, created_at, updated_at)
        VALUES ('#{tag_name}', 'country_region', 'Nigerian diaspora community in #{tag_name}', true, false, NOW(), NOW())
      SQL
    end

    # Create special project tags
    special_project_data.each do |tag_data|
      next if execute("SELECT COUNT(*) FROM approved_tags WHERE LOWER(name) = '#{tag_data[:name].downcase}'").first['count'] > 0
      
      execute <<-SQL
        INSERT INTO approved_tags (name, category, description, is_active, is_featured, created_at, updated_at)
        VALUES ('#{tag_data[:name]}', 'special_project', '#{tag_data[:description]}', true, true, NOW(), NOW())
      SQL
    end

    puts "✅ Approved tags migration completed!"
  end

  def down
    # Remove all approved tags (reversible migration)
    execute "DELETE FROM approved_tags"
    puts "Approved tags migration rolled back"
  end
end