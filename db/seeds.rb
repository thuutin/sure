# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts 'Run the following command to create demo data: `rake demo_data:default`' if Rails.env.development?

ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF;")
ActiveRecord::Base.transaction do
  Dir[Rails.root.join('db', 'seeds', '*.rb')].sort.each do |file|
    puts "Loading seed file: #{File.basename(file)}"
    if File.basename(file) == "db_restore.rb" && Family.count > 0
      puts "Skipping db_restore.rb because data already exists"
      next
    end
    require file
  end
end
ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON;")
