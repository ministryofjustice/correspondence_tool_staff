require 'rails_helper'

module Stats


  describe R006KiloMap do

    it 'produces a kilo map as a csv' do

      dacu_disclosure = BusinessUnit.dacu_disclosure
      dacu_disclosure.users.map(&:destroy)
      dacu_disclosure.team_lead = 'Jeremy Corbyn'

      create :manager, full_name: 'Theresa May', email: 'tm@pm.gov.uk', managing_teams: [dacu_disclosure]
      create :manager, full_name: 'David Cameron', email: 'dc@pm.gov.uk', managing_teams: [dacu_disclosure]
      create :manager, full_name: 'Gordon Brown', email: 'gb@pm.gov.uk', managing_teams: [dacu_disclosure]

      map = R006KiloMap.new
      map.run


      csv_lines = map.to_csv.split("\n")

      ap csv_lines

      expect(csv_lines.shift).to eq header_line
      expect(csv_lines.shift).to match business_group_line
      expect(csv_lines.shift).to match directorate_line
      expect(csv_lines.shift).to eq disclosure_line_1
      expect(csv_lines.shift).to eq disclosure_line_2
      expect(csv_lines.shift).to eq disclosure_line_3
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

    def disclosure_line_1
      %{"","",Disclosure,Jeremy Corbyn,Hammersmith,dacu.disclosure@localhost,David Cameron,dc@pm.gov.uk}
    end

    def disclosure_line_2
      %{"","","","","","",Gordon Brown,gb@pm.gov.uk}
    end

    def disclosure_line_3
      %{"","","","","","",Theresa May,tm@pm.gov.uk}
    end

    def operations_line
      /Operations,"","",Director General \d{1,5}/
    end

    def dacu_directorate_line
      /"",DACU Directorate,"",Director \d{1,5}/
    end

    def dacu_line
      /"","",Disclosure BMT,Deputy Director \d{1,5},Hammersmith,dacu@localhost,user \d{1,5},/
    end

    def press_office_directorate_line
      /"",Press Office Directorate,"",Director \d{1,5}/
    end

    def press_office_line
      /"","",Press Office,Deputy Director \d{1,5},Hammersmith,press.office@localhost,user \d{1,5},/
    end

    def private_office_line
      /"","",Private Office,Deputy Director \d{1,5},Hammersmith,private.office@localhost,user \d{1,5},/
    end

  end
end
