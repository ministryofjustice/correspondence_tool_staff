require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  describe R901OffenderSARCasesReport do
    before(:all) { DbHousekeeping.clean(seed: true) }

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    describe ".title" do
      it "returns correct title" do
        expect(described_class.title).to eq "Cases report for Offender SAR and Complaint"
      end
    end

    describe ".description" do
      it "returns correct description" do
        expect(described_class.description)
          .to eq "The list of Offender SAR and Complaint cases within allowed and filtered scope"
      end
    end

    describe "#analyse_case" do
      before do
        create_report_type(abbr: :r901)
      end

      it "returns correct columns for offender sar" do
        report = described_class.new
        offender_sar_case = create :offender_sar_case, :waiting_for_data,
                                   subject_type: "ex_probation_service_user",
                                   subject_full_name: "testing analyse_case"
        result = report.analyse_case(offender_sar_case)
        expect(result).to include(
          offender_sar_case.number,
          offender_sar_case.decorate.pretty_type,
          "",
          "",
          offender_sar_case.received_date,
          offender_sar_case.external_deadline,
          "",
          "Data subject",
          nil,
          "testing analyse_case",
          "Ex-probation service user",
          0,
          "in time",
          "Waiting for data",
          offender_sar_case.num_days_taken,
          "No",
        )
      end

      it "returns correct columns for offender sar complaint" do
        report = described_class.new
        offender_sar_complaint = create :accepted_complaint_case, :waiting_for_data,
                                        subject_type: "ex_probation_service_user",
                                        subject_full_name: "testing analyse_complaint_case"
        result = report.analyse_case(offender_sar_complaint)
        expect(result).to include(
          offender_sar_complaint.number,
          offender_sar_complaint.decorate.pretty_type,
          offender_sar_complaint.complaint_subtype.humanize,
          "Normal",
          offender_sar_complaint.received_date,
          offender_sar_complaint.external_deadline,
          offender_sar_complaint.responder.full_name,
          "Data subject",
          nil,
          "testing analyse_complaint_case",
          "Ex-probation service user",
          0,
          "in time",
          "Waiting for data",
          offender_sar_complaint.num_days_taken,
          "No",
        )
      end
    end

    describe "#case_scope" do
      before do
        create_report_type(abbr: :r901)
      end

      before(:all) do
        @sar_1 = create :accepted_sar, identifier: "sar-1"
        @offender_sar_1 = create :offender_sar_case, :waiting_for_data, identifier: "osar-1"

        @sar_2 = create :accepted_ico_foi_case, identifier: "sar-2"
        @offender_sar_2 = create :offender_sar_case, :closed, identifier: "osar-2"

        @sar_3 = create :accepted_sar, identifier: "sar-3"
        @offender_sar_3 = create :offender_sar_case, :data_to_be_requested, identifier: "osar-3"

        @sar_4 = create :accepted_sar, identifier: "sar-4"
        @offender_sar_4 = create :offender_sar_case, :ready_to_copy, identifier: "osar-4"

        @offender_sar_complaint_1 = create :offender_sar_complaint, :ready_to_copy, identifier: "osar-complaint-4"
      end

      it "returns only Offender SAR related cases with initial scope of nil" do
        report = described_class.new
        expect(report.case_scope).to match_array([
          @offender_sar_1,
          @offender_sar_2,
          @offender_sar_3,
          @offender_sar_4,
          @offender_sar_complaint_1.original_case,
          @offender_sar_complaint_1,
        ])
      end

      it "returns only Offender SAR related cases with initial scope of ready-to-copy cases being asked" do
        report = described_class.new(case_scope: Case::SAR::Offender.all.where(current_state: "ready_to_copy"))
        expect(report.case_scope).to match_array([@offender_sar_4, @offender_sar_complaint_1])
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
