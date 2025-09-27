namespace :seed_dump do
  desc "Dump database to seeds file with specific exclusions"
  task dump: :environment do
    puts "Starting seed dump with exclusions..."

    # Run the seed dump command with the specified parameters
    system("rails db:seed:dump IMPORT=true EXCLUDE= models_exclude=RailsSettings::Base,Import,Import::Mapping,ToolCall,Message,Doorkeeper::Application")

    if $?.success?
      puts "Seed dump completed successfully!"
      puts "Check db/seeds.rb for the generated seed data."
    else
      puts "Seed dump failed with exit code #{$?.exitstatus}"
      exit 1
    end
  end

  desc "Dump database to seeds file with custom exclusions"
  task :dump_custom, [ :exclude_models ] => :environment do |t, args|
    exclude_models = args[:exclude_models] || "RailsSettings::Base,Import,Import::Mapping,ToolCall,Message,Doorkeeper::Application"

    puts "Starting seed dump with custom exclusions: #{exclude_models}"

    # Run the seed dump command with custom exclusions
    system("rails db:seed:dump IMPORT=true EXCLUDE= models_exclude=#{exclude_models}")

    if $?.success?
      puts "Seed dump completed successfully!"
      puts "Check db/seeds.rb for the generated seed data."
    else
      puts "Seed dump failed with exit code #{$?.exitstatus}"
      exit 1
    end
  end

  desc "Show help for seed dump options"
  task help: :environment do
    puts <<~HELP
      Seed Dump Tasks:

      rake seed_dump:dump
        - Runs seed dump with default exclusions
        - Excludes: RailsSettings::Base, Import, Import::Mapping, ToolCall, Message, Doorkeeper::Application

      rake seed_dump:dump_custom["Model1,Model2,Model3"]
        - Runs seed dump with custom model exclusions
        - Example: rake seed_dump:dump_custom["User,Account,Transaction"]

      rake seed_dump:help
        - Shows this help message

      The generated seeds will be written to db/seeds.rb
    HELP
  end
end
