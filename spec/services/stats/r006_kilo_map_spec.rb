require 'rails_helper'

module Stats


  describe R006KiloMap do

    it 'produces a kilo map as a csv' do
      map = R006KiloMap.new
      map.run
      csv_lines = map.to_csv.split("\n")
      expect(csv_lines.shift).to eq header_line
      expect(csv_lines.shift).to match business_group_line
      expect(csv_lines.shift).to match directorate_line
      expect(csv_lines.shift).to match disclosure_line
      expect(csv_lines.shift).to match operations_line
      expect(csv_lines.shift).to match dacu_directorate_line
      expect(csv_lines.shift).to match dacu_line
      expect(csv_lines.shift).to match press_office_directorate_line
      expect(csv_lines.shift).to match press_office_line
      expect(csv_lines.shift).to match private_office_line
    end

    def header_line
      %{Business group,Directorate,Business unit,Director General / Director / Deputy Director,Areas covered,Group email,Team member name,Team member email}
    end

    def business_group_line
      /Business Group \d{1,5},"","",Director General \d{1,5}/
    end

    def directorate_line
      /"",Directorate \d{1,5},"",Director \d{1,5}/
    end

    def disclosure_line
      /"","",Disclosure,Deputy Director \d{1,5},Hammersmith,dacu.disclosure@localhost,Disclosure Specialist \d{1,5},/
    end

    def operations_line
      /Operations,"","",Director General \d{1,5}/
    end

    def dacu_directorate_line
      /"",DACU Directorate,"",Director \d{1,5}/
    end

    def dacu_line
      /"","",Disclosure BMT,Deputy Director \d{1,5},Hammersmith,dacu@localhost,Firstname\d{1,5} Lastname\d{1,5},/
    end

    def press_office_directorate_line
      /"",Press Office Directorate,"",Director \d{1,5}/
    end

    def press_office_line
      /"","",Press Office,Deputy Director \d{1,5},Hammersmith,press.office@localhost,Firstname\d{1,5} Lastname\d{1,5},/
    end

    def private_office_line
      /"","",Private Office,Deputy Director \d{1,5},Hammersmith,private.office@localhost,Firstname\d{1,5} Lastname\d{1,5},/
    end

  end
end
