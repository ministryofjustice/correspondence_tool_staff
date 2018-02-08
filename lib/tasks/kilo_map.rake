task :kilo_map => :environment do
  require 'csv'
  CSV.foreach(File.join(Rails.root, 'lib', 'assets', 'kilo_map.csv')) do |row|
    puts row.inspect
    next if header_row?(row)
    bg, bu, sar = row
    sar_correspondence_type = CorrespondenceType.sar
    if bg.present?
      @bg = BusinessGroup.find_by_name bg
    end
    if @bg.nil?
      puts ">>>>>>>>>>>> UNABLE TO FIND BUSINESS GROUP #{bg} #{__FILE__}:#{__LINE__} <<<<<<<<<<<<\n"
    else
      if @bg.present?
        if sar == 'YES'
          business_unit = @bg.business_units.find_by_name(bu)
          if business_unit.nil?
            puts ">>>>>>>>>>>> unable to find BU #{bu} IN BG #{@bg.name} #{__FILE__}:#{__LINE__} <<<<<<<<<<<<\n"
          else
            business_unit.correspondence_type << sar_correspondence_type
            puts "Updating BU #{business_unit.id} #{business_unit.name}"
          end
        end
      end
    end
  end

end


def header_row?(row)
  bg, _bu, _sar = row
  bg == 'Business group'
end

