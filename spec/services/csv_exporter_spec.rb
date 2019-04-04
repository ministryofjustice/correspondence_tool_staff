require 'rails_helper'

describe CSVExporter do
  let(:late_team) {
    create :responding_team,
      name: 'Transport for London'
  }

  let(:late_foi_case) {
    create :closed_case,
      :fully_refused_exempt_s40,
      :late,
      :flagged,
      name: 'FOI Case name',
      email: 'dave@moj.com',
      message: 'foi message',
      postal_address: nil,
      late_team_id: late_team.id
  }

  let(:sar_case) {
    create :closed_sar,
      name: 'SAR case name',
      postal_address: "2 High Street\nAnytown\nAY2 4FF",
      subject: 'Full details required',
      email: 'theresa@moj.com',
      message: 'my SAR message',
      subject_full_name: 'Theresa Cant'
  }

  let(:extended_case) {
    create :closed_case,
      :fully_refused_exempt_s40,
      :extended_for_pit,
      name: 'FOI Case name',
      email: 'dave@moj.com',
      message: 'foi message',
      postal_address: nil
  }

  # These columns can have arbitrary values as they are
  # set by Faker within their respective factories
  let(:transient_columns) {
    [
      'Director General name',
      'Director name',
      'Deputy Director name',
    ]
  }

  context 'ICO' do
    context 'FOI' do
      let(:ico_case) { create(:overturned_ico_foi) }

      it 'returns an array of fields' do
        csv = CSVExporter.new(ico_case).to_csv
        expect(csv.size).to eq(CSVExporter::CSV_COLUMN_HEADINGS.size)
      end
    end

    context 'SAR' do
      let(:ico_case) { create(:overturned_ico_sar) }

      it 'returns an array of fields' do
        csv = CSVExporter.new(ico_case).to_csv
        expect(csv.size).to eq(CSVExporter::CSV_COLUMN_HEADINGS.size)
      end
    end
  end

  context 'late FOI' do
    it 'returns an array of fields' do
      Timecop.freeze Time.local(2018, 10, 1, 13, 21, 33) do
        csv = CSVExporter.new(late_foi_case).to_csv
        expect(csv.size).to eq(CSVExporter::CSV_COLUMN_HEADINGS.size)

        result = CSVExporter::CSV_COLUMN_HEADINGS.zip(csv).to_h

        # Test transient columns before removing them from +result+ hash
        transient_columns.each { |key| expect(result[key]).not_to be_blank }

        expect(result.except!(*transient_columns)).to eq({
          'Number' => '180817001',
          'Case type' => 'FOI',
          'Current state' => 'Closed',
          'Responding team' => 'FOI Responding Team',
          'Responder' => 'foi responding user',
          'Date received' => '2018-08-17',
          'Internal deadline' => '2018-09-03',
          'External deadline' => '2018-09-17',
          'Date responded' => '2018-09-28',
          'Date compliant draft uploaded' => '2018-09-28',
          'Trigger' => 'Yes',
          'Name' => 'FOI Case name',
          'Requester type' => 'Member of the public',
          'Message' => 'foi message',
          'Info held' => 'Yes',
          'Outcome' => 'Refused fully',
          'Refusal reason' => nil,
          'Exemptions' => 's40',
          'Postal address' => nil,
          'Email' => 'dave@moj.com',
          'Appeal outcome' => nil,
          'Third party' => nil,
          'Reply method' => nil,
          'SAR Subject type' => nil,
          'SAR Subject full name' => nil,
          'Business unit responsible for late response' => late_team.name,
          'Extended' => 'No',
          'Extension Count' => 0,
          'Deletion Reason' => nil,
          'Casework officer' => nil,
          'Created by' => late_foi_case.creator.full_name,
          'Date created' => '2018-09-25',
          'Business group' => 'Responder Business Group',
          'Directorate name' => 'Responder Directorate',
          'Draft in time' => nil,
          'In target' => 'Yes',
          'Number of days late' => 25,
        })
      end
    end
  end

  context 'extended' do
    let(:csv_data) do
      Timecop.freeze Time.local(2018, 10, 1, 13, 21, 33) do
        CSVExporter::CSV_COLUMN_HEADINGS.zip(CSVExporter.new(kase).to_csv).to_h
      end
    end

    context 'deleted' do
      let(:kase) { create(:case, :deleted_case) }

      it 'returns the deletion reason' do
        expect(csv_data).to include({
          'Deletion Reason' => kase.reason_for_deletion
        })
      end
    end

    context 'FOI' do
      let(:kase) { create :closed_case,
        :fully_refused_exempt_s40,
        :pit_extension_removed,
        :extended_for_pit,
        message: 'foi message',
        postal_address: nil
      }

      it 'marks case as having an extended count of 1' do
        expect(csv_data).to include({
          'Extended' => 'Yes',
          'Extension Count' => 1
        })
      end
    end

    context 'SAR' do
      context 'extended' do
        let(:kase) {
          create(
            :closed_sar,
            :extended_deadline_sar,
            message: 'my SAR message',
            subject_full_name: 'Theresa Cant'
          )
        }

        it 'marks an extended SAR having an extended count of 1' do
          expect(csv_data).to include({
            'Extended' => 'Yes',
            'Extension Count' => 1
          })
        end
      end

      context 'extension removed' do
        let!(:kase) do
          create(
            :sar_case,
            :extended_deadline_sar,
            current_state: 'drafting',
            message: 'my SAR message',
            subject_full_name: 'Theresa Cant'
          ).tap do |k|
            CaseRemoveSARDeadlineExtensionService.new(
              k.transitions.last.acting_user,
              k
            ).call
          end
        end

        it 'ignores the removed extension' do
          expect(csv_data).to include({
            'Extended' => 'No',
            'Extension Count' => 0
          })
        end
      end
    end
  end

  context 'SAR' do
    it 'returns sar fields' do
      Timecop.freeze Time.local(2018, 10, 1, 13, 21, 33) do
        csv = CSVExporter.new(sar_case).to_csv
        expect(csv.size).to eq(CSVExporter::CSV_COLUMN_HEADINGS.size)

        result = CSVExporter::CSV_COLUMN_HEADINGS.zip(csv).to_h

        # Test transient columns before removing them from +result+ hash
        transient_columns.each { |key| expect(result[key]).not_to be_blank }

        expect(result.except!(*transient_columns)).to eq({
          'Number' => '180830001',
          'Case type' => 'SAR',
          'Current state' => 'Closed',
          'Responding team' => 'SAR Responding Team',
          'Responder' => 'sar responding user',
          'Date received' => '2018-08-30',
          'Internal deadline' => nil,
          'External deadline' => '2018-09-29',
          'Date responded' => '2018-09-25',
          'Date compliant draft uploaded' => nil,
          'Trigger' => nil,
          'Name' => 'SAR case name',
          'Requester type' => nil,
          'Message' => 'my SAR message',
          'Info held' => nil,
          'Outcome' => nil,
          'Refusal reason' => nil,
          'Exemptions' => '',
          'Postal address' => "2 High Street\nAnytown\nAY2 4FF",
          'Email' => 'theresa@moj.com',
          'Appeal outcome' => nil,
          'Third party' => nil,
          'Reply method' => 'Send by email',
          'SAR Subject type' => 'Offender',
          'SAR Subject full name' => 'Theresa Cant',
          'Business unit responsible for late response' => 'N/A',
          'Extended' => 'No',
          'Extension Count' => 0,
          'Deletion Reason' => nil,
          'Casework officer' => nil,
          'Created by' => sar_case.creator.full_name,
          'Date created' => '2018-09-25',
          'Business group' => 'Responder Business Group',
          'Directorate name' => 'Responder Directorate',
          'Draft in time' => nil,
          'In target' => 'Yes',
          'Number of days late' => nil,
        })
      end
    end
  end
end
