namespace :kilo_map do


  desc 'Updates business units requiring rights to respond to SARs'
  task :load_sars, [:filename] => :environment do | _task, args|
    if args[:filename].present?
      require File.join(Rails.root, 'lib', 'tasks', 'rake_task_helpers', 'sars_loader.rb')
      loader = SarsLoader.new(args[:filename])
      loader.run
    else
      puts "ERROR! Invoke with filename, e.g. 'rake kilo_map:load_sars[filename]'"
      exit 2
    end

  end



  desc 'lists business units and what correspondence types they deal with'
  task :audit_corr_types => :environment do
    BusinessGroup.all.each do |bg|
      bg.business_units.each do |bu|
        puts sprintf('%-4d %-40s %-60s %s', bu.id, bg.name, bu.name, bu.correspondence_types.map(&:abbreviation).join(", "))
      end
    end
  end


  def header_row?(row)
    bg, _bu, _sar = row
    bg == 'Business group'
  end
end


