require 'csv'

class TeamImporter

  FILENAME = File.join(ENV['HOME'], 'Dropbox', 'team_data.csv')


  def intialize
    @bg = nil
    @dir = nil
    @bu = nil
  end

  def run
    CSV.foreach(FILENAME) do |row|
      process_row(row)
    end
  end

  private

  def process_row(row)
    case what_type_of_row?(row)
      when :header
        nil
      when :business_group
        process_business_group(row)
      when :directorate
        process_directorate(row)
      when :business_unit
        process_business_unit(row)
      when :area
        process_area(row)
    end
  end

  def process_business_group(row)
    puts "Creating Business group #{row.first}"
    @dir = nil
    @bu = nil
    bg, _dir, _bu, lead, _area = row
    @bg = BusinessGroup.create!(name: bg, email: default_email(bg))
    @bg.properties << TeamProperty.new(key: 'lead', value: lead)
    @bg.save!
  end

  def process_directorate(row)
    puts "    Adding Directorate #{row[1]} to #{@bg.name}"
    @bu = nil
    _bg, dir, _bu, lead, area = row
    @dir = Directorate.new(name: dir, email: default_email(dir))
    @dir.properties << TeamProperty.new(key: 'lead', value: lead)
    @dir.properties << TeamProperty.new(key: 'area', value: area) if area.present?
    @bg.directorates << @dir
    @bg.save!
  end

  def process_business_unit(row)
    puts "        Business Unit #{row[2]}"
    @bu.save! unless @bu.nil?
    _bg, _dir, bu, lead, area = row
    @bu = BusinessUnit.new(parent_id: @dir.id, name: bu, email: default_email(bu))
    @bu.properties << TeamProperty.new(key: 'lead', value: lead)
    @bu.properties << TeamProperty.new(key: 'area', value: area) if area.present?
    @bu.properties << TeamProperty.new(key: 'can_allocae', value: 'FOI')
    @bu.save!
  end

  def process_area(row)
    puts "            Area #{row[4]}"
    _bg, _dir, _bu, _lead, area = row
    @bu.properties << TeamProperty.new(key: 'area', value: area) if area.present?
  end

  def what_type_of_row?(row)
    if row.first == 'Business Unit Group'
      :header
    else
      bg, dir, bu, _lead, _area  = row
      if bg.present?
        :business_group
      elsif dir.present?
        :directorate
      elsif bu.present?
        :business_unit
      else
        :area
      end
    end
  end

  def header?(row)
    row.first == 'Business Unit Group'
  end

  def default_email(_name)
    # leave blank for now
    # "correspondence-staff-dev+#{normalize(name)}-team@digital.justice.gov.uk"
    nil
  end

  def normalize(name)
    name.downcase.tr(' ', '_').tr('&', '_')
  end
end
