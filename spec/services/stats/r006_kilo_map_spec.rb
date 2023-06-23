require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  describe R006KiloMap do
    before(:all) do
      DbHousekeeping.clean(seed: true)
      create_report_type(abbr: :r006)
    end

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    it "produces a kilo map as a csv" do
      dacu_disclosure = BusinessUnit.dacu_disclosure
      dacu_disclosure.users.map(&:destroy)
      dacu_disclosure.team_lead = "Jeremy Corbyn"
      dacu_branston = BusinessUnit.dacu_branston
      dacu_branston.users.map(&:destroy)
      dacu_disclosure.team_lead = "David Gauke"

      create :manager, full_name: "Theresa May", email: "tm@pm.gov.uk", managing_teams: [dacu_disclosure]
      create :manager, full_name: "David Cameron", email: "dc@pm.gov.uk", managing_teams: [dacu_disclosure]
      create :manager, full_name: "Gordon Brown", email: "gb@pm.gov.uk", managing_teams: [dacu_disclosure]
      create :manager, full_name: "David Gauke", email: "dg@pm.gov.uk", managing_teams: [dacu_branston]

      map = described_class.new
      map.run

      expect(map.persist_results?).to eq false
      expect(map.report_type).to eq ReportType.r006

      csv_lines = map.to_csv.map { |row| row.map(&:value) }

      expect(csv_lines).to eq map.results

      expect(csv_lines.shift).to eq header_line.split(",")
      expect(CSV.generate_line(csv_lines.shift).chomp).to match operations_line
      expect(CSV.generate_line(csv_lines.shift).chomp).to match dacu_directorate_line
      expect(CSV.generate_line(csv_lines.shift).chomp).to match disclosure_line_0
      expect(CSV.generate_line(csv_lines.shift).chomp).to eq disclosure_line_1
      expect(CSV.generate_line(csv_lines.shift).chomp).to eq disclosure_line_2
      expect(CSV.generate_line(csv_lines.shift).chomp).to eq disclosure_line_3
      expect(CSV.generate_line(csv_lines.shift).chomp).to match dacu_line
      expect(CSV.generate_line(csv_lines.shift).chomp).to match press_office_directorate_line
      expect(CSV.generate_line(csv_lines.shift).chomp).to match press_office_line
      # expect(csv_lines.shift).to match press_office_second_user_line
      expect(CSV.generate_line(csv_lines.shift).chomp).to match private_office_line
      # expect(csv_lines.shift).to match private_office_second_user_line

      map.set_results([%w[test]])
      expect(map.results).to eq [%w[test]]
    end

    def header_line
      %(Business group,Directorate,Business unit,Director General / Director / Deputy Director,Areas covered,Group email,Team member name,Team member email)
    end

    def operations_line
      /Operations,"","",Director General \d{1,5}/
    end

    def dacu_directorate_line
      /"",DACU Directorate,"",Director \d{1,5}/
    end

    def disclosure_line_0
      /"","",Branston Registry,Deputy Director \d{1,5},Hammersmith,branston@localhost/
    end

    def disclosure_line_1
      %("","",Disclosure,David Gauke,Hammersmith,dacu.disclosure@localhost,David Cameron,dc@pm.gov.uk)
    end

    def disclosure_line_2
      %("","","","","","",Gordon Brown,gb@pm.gov.uk)
    end

    def disclosure_line_3
      %("","","","","","",Theresa May,tm@pm.gov.uk)
    end

    def dacu_line
      /"","",Disclosure BMT,Deputy Director \d{1,5},Hammersmith,dacu@localhost,disclosure-bmt managing user,/
    end

    def press_office_directorate_line
      /"",Press Office Directorate,"",Director \d{1,5}/
    end

    def press_office_line
      # /"","",Press Office,Deputy Director \d{1,5},Hammersmith,press.office@localhost,Press Officer \d{1,5},/
      /"","",Press Office,Deputy Director \d{1,5},Hammersmith,press.office@localhost,press-office approving user,/
    end

    def press_office_second_user_line
      /"","","","","",user \d{1,5},/
    end

    def private_office_line
      # /"","",Private Office,Deputy Director \d{1,5},Hammersmith,private.office@localhost,Private Officer \d{1,5},/
      /"","",Private Office,Deputy Director \d{1,5},Hammersmith,private.office@localhost,private-office approving user,/
    end

    def private_office_second_user_line
      /"","","","","",user \d{1,5},/
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
