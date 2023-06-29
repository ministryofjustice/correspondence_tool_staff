require "csv"

class TeamSeeder
  FILENAME = ENV["TEAM_IMPORT_CSV"]

  def initialize
    raise "Set TEAM_IMPORT_CSV env var to point to the CSV file containing team data" if FILENAME.blank?

    @bg = nil
    @dir = nil
    @bu = nil
  end

  def seed!
    CSV.foreach(FILENAME) do |row|
      process_row(row)
    end
    add_hq_teams
  end

private

  def add_hq_teams
    bg_ops = BusinessGroup.find_by!(name: "Operations")
    dir_dacu = Directorate.create!(parent: bg_ops, name: "DACU")
    dir_private = Directorate.create!(parent: bg_ops, name: "Private Office")
    dir_press = Directorate.create!(parent: bg_ops, name: "Press Office")
    BusinessUnit.create!(parent: dir_dacu, code: Settings.foi_cases.default_managing_team, name: "Disclosure BMT")
    BusinessUnit.create!(parent: dir_dacu, code: Settings.foi_cases.default_clearance_team, name: "Disclosure")
    BusinessUnit.create!(parent: dir_private, code: Settings.private_office_team_code, name: "Private Office")
    BusinessUnit.create!(parent: dir_press, code: Settings.press_office_team_code, name: "Press Office")
  end

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
    Rails.logger.debug "Creating Business group #{row.first}"
    @dir = nil
    @bu = nil
    bg, _dir, _bu, lead, _area = row
    @bg = BusinessGroup.create!(name: bg, email: default_email(bg))
    @bg.properties << TeamProperty.new(key: "lead", value: lead)
    @bg.save!
  end

  def process_directorate(row)
    Rails.logger.debug "    Adding Directorate #{row[1]} to #{@bg.name}"
    @bu = nil
    _bg, dir, _bu, lead, area = row
    @dir = Directorate.new(name: dir, email: default_email(dir))
    @dir.properties << TeamProperty.new(key: "lead", value: lead)
    @dir.properties << TeamProperty.new(key: "area", value: area) if area.present?
    @bg.directorates << @dir
    @bg.save!
  end

  def process_business_unit(row)
    Rails.logger.debug "        Business Unit #{row[2]}"
    @bu.save! unless @bu.nil?
    _bg, _dir, bu, lead, area = row
    @bu = BusinessUnit.new(parent_id: @dir.id, name: bu, email: default_email(bu))
    @bu.properties << TeamProperty.new(key: "lead", value: lead)
    @bu.properties << TeamProperty.new(key: "area", value: area) if area.present?
    @bu.properties << TeamProperty.new(key: "can_allocate", value: "FOI")
    @bu.save!
  end

  def process_area(row)
    Rails.logger.debug "            Area #{row[4]}"
    _bg, _dir, _bu, _lead, area = row
    @bu.properties << TeamProperty.new(key: "area", value: area) if area.present?
  end

  def what_type_of_row?(row)
    if row.first == "Business Unit Group"
      :header
    else
      bg, dir, bu, _lead, _area = row
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
    row.first == "Business Unit Group"
  end

  def default_email(_name)
    # leave blank for now
    # "correspondence-staff-dev+#{normalize(name)}-team@digital.justice.gov.uk"
    nil
  end

  def normalize(name)
    name.downcase.tr(" ", "_").tr("&", "_")
  end
end
