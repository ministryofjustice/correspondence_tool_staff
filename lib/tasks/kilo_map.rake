def header_row?(row)
  bg, _bu, _sar = row
  bg == "Business group"
end

namespace :kilo_map do
  desc "Updates business units requiring rights to respond to SARs"
  task :load_sars, [:filename] => :environment do |_task, args|
    if args[:filename].present?
      require Rails.root.join("lib/tasks/rake_task_helpers/sars_loader.rb")
      loader = SARsLoader.new(args[:filename])
      loader.run
    else
      puts "ERROR! Invoke with filename, e.g. 'rake kilo_map:load_sars[filename]'"
      exit 2
    end
  end

  desc "lists business units and what correspondence types they deal with"
  task audit_corr_types: :environment do
    BusinessGroup.all.find_each do |bg|
      bg.business_units.each do |bu|
        puts sprintf("%-4d %-40s %-60s %s", bu.id, bg.name, bu.name, bu.correspondence_types.map(&:abbreviation).join(", "))
      end
    end
  end
end
