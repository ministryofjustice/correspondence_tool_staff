require "csv"

# This class is used for loading a list of teams into the dev database from the R006_kilo_map CSV
# file (useful for testing scripts to assign correpsondence types to certain business units only)
#
class SarsLoader
  def initialize(filename)
    @filename = filename
    @foi = CorrespondenceType.find_by(abbreviation: "FOI")
    @sar = CorrespondenceType.find_by(abbreviation: "SAR")
  end

  def run
    CSV.foreach(@filename) do |row|
      bg, bu, sars = row

      next if bg == "Business group"   # header row

      if bg.present?
        process_business_group(bg)
      elsif bu.present? && sars.present?
        process_business_unit(bu)
      end
    end
  end

private

  def process_business_group(business_group)
    @bg = BusinessGroup.find_by(name: business_group)
    if @bg.nil?
      puts ">>>>>>>>>> ERROR <<<<<<<<<<<< Unable to find BG #{@bg.name}"
    end
  end

  def process_business_unit(business_unit)
    bus = @bg.business_units.where("teams.name LIKE ?", "%#{business_unit}%")
    if bus.empty?
      puts ">>>>>>>>>> ERROR <<<<<<<<<<<< Unable to find BU #{business_unit} under BG #{@bg.name}"
    elsif bus.size > 1
      puts ">>>>>>>>>> ERROR <<<<<<<<<<<< Mulitple business units found with name matchng %#{business_unit}% under BG #{@bg.name}"
    else
      business_unit = bus.first
      business_unit.update!(correspondence_type_ids: [@foi.id, @sar.id])
      business_unit.save!
    end
  end
end
