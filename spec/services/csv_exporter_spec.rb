require 'rails_helper'

describe CSVExporter do

  let(:late_team) { create :responding_team, name: 'Transport for London' }
  let(:late_foi_case) { create :closed_case, :fully_refused_exempt_s40,
                          :late,
                          name: 'FOI Case name',
                          email: 'dave@moj.com',
                          message: 'foi message',
                          postal_address: nil,
                          late_team_id: late_team.id
  }
  let(:sar_case) { create :closed_sar,
                          name: 'SAR case name',
                          postal_address: "2 High Street\nAnytown\nAY2 4FF",
                          subject: 'Full details required',
                          email: 'theresa@moj.com',
                          message: 'my SAR message',
                          subject_full_name: 'Theresa Cant'
  }
  let(:extended_case)          { create :closed_case, :fully_refused_exempt_s40,
                                        :extended_for_pit,
                                   name: 'FOI Case name',
                                   email: 'dave@moj.com',
                                   message: 'foi message',
                                   postal_address: nil }

  context 'late FOI' do
    it 'returns an array of fields' do
      Timecop.freeze Time.local(2018, 10, 1, 13, 21, 33) do
        csv = CSVExporter.new(late_foi_case).to_csv
        expect(csv).to eq [
                             '180817001',
                             'FOI',
                             'closed',
                             'FOI Responding Team',
                             'foi responding user',
                             '2018-08-17',
                             '2018-09-03',
                             '2018-09-17',
                             '2018-09-28',
                             'standard',
                             'FOI Case name',
                             'member_of_the_public',
                             'foi message',
                             'Yes',
                             'Refused fully',
                             nil,
                             's40',
                             nil,
                             'dave@moj.com',
                             nil,
                             nil,
                             nil,
                             nil,
                             nil,
                             late_team.name,
                             'No',
                             0
                          ]
      end
    end
  end

  context 'extended' do
    it 'marks an extended case as extended' do
      Timecop.freeze Time.local(2018, 10, 1, 13, 21, 33) do
        csv = CSVExporter.new(extended_case).to_csv
        expect(csv[24]).to eq 'Yes'
      end
    end
  end

  context 'SAR' do
    it 'returns sar fields' do
      Timecop.freeze Time.local(2018, 10, 1, 13, 21, 33) do
        csv = CSVExporter.new(sar_case).to_csv
        expect(csv).to eq [
                              '180830001',
                              'SAR',
                              'closed',
                              'SAR Responding Team',
                              'sar responding user',
                              '2018-08-30',
                              '2018-09-09',
                              '2018-09-29',
                              '2018-09-25',
                              'standard',
                              'SAR case name',
                              nil,
                              'my SAR message',
                              nil,
                              nil,
                              nil,
                              '',
                              "2 High Street\nAnytown\nAY2 4FF",
                              'theresa@moj.com',
                              nil,
                              false,
                              'send_by_email',
                              'offender',
                              'Theresa Cant',
                              'N/A',
                              'No',
                              0
                          ]
      end
    end
  end
end
