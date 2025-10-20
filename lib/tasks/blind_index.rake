namespace :blind_index do
desc "Compute blind index values for all existing users emails"
task compute_email: :environment do
    puts "Starting to compute blind index values for user emails..."

    begin
    total_users = User.count
    processed = 0
    failed = 0

    User.find_each(batch_size: 100) do |user|
        begin
        # Save will trigger the blind index computation
        if user.save(validate: false)
            processed += 1
        else
            failed += 1
            puts "Failed to update user #{user.id}: #{user.errors.full_messages.join(', ')}"
        end

        # Show progress every 100 records
        if processed % 100 == 0
            puts "Processed #{processed}/#{total_users} users (#{failed} failed)"
        end
        rescue => e
        failed += 1
        puts "Error processing user #{user.id}: #{e.message}"
        end
    end

    puts "\nCompleted processing blind index values:"
    puts "Total users: #{total_users}"
    puts "Successfully processed: #{processed}"
    puts "Failed: #{failed}"
    rescue => e
    puts "Fatal error occurred: #{e.message}"
    puts e.backtrace
    raise e
    end
end
end
