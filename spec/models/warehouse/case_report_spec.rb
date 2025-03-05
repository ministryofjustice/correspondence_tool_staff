# == Schema Information
#
# Table name: warehouse_case_reports
#
#  case_id                                     :integer          not null, primary key
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  creator_id                                  :integer
#  responding_team_id                          :integer
#  responder_id                                :integer
#  casework_officer_user_id                    :integer
#  business_group_id                           :integer
#  directorate_id                              :integer
#  director_general_name_property_id           :integer
#  director_name_property_id                   :integer
#  deputy_director_name_property_id            :integer
#  number                                      :string
#  case_type                                   :string
#  current_state                               :string
#  responding_team                             :string
#  responder                                   :string
#  date_received                               :date
#  internal_deadline                           :date
#  external_deadline                           :date
#  date_responded                              :date
#  date_compliant_draft_uploaded               :date
#  trigger                                     :string
#  name                                        :string
#  requester_type                              :string
#  message                                     :string
#  info_held                                   :string
#  outcome                                     :string
#  refusal_reason                              :string
#  exemptions                                  :string
#  postal_address                              :string
#  email                                       :string
#  appeal_outcome                              :string
#  third_party                                 :string
#  reply_method                                :string
#  sar_subject_type                            :string
#  sar_subject_full_name                       :string
#  business_unit_responsible_for_late_response :string
#  extended                                    :string
#  extension_count                             :integer
#  deletion_reason                             :string
#  casework_officer                            :string
#  created_by                                  :string
#  date_created                                :datetime
#  business_group                              :string
#  directorate_name                            :string
#  director_general_name                       :string
#  director_name                               :string
#  deputy_director_name                        :string
#  draft_in_time                               :string
#  in_target                                   :string
#  number_of_days_late                         :integer
#  info_held_status_id                         :integer
#  refusal_reason_id                           :integer
#  outcome_id                                  :integer
#  appeal_outcome_id                           :integer
#  number_of_days_taken                        :integer
#  number_of_exempt_pages                      :integer
#  number_of_final_pages                       :integer
#  third_party_company_name                    :string
#  number_of_days_taken_after_extension        :integer
#  complaint_subtype                           :string
#  priority                                    :string
#  total_cost                                  :decimal(10, 2)
#  settlement_cost                             :decimal(10, 2)
#  user_dealing_with_vetting                   :string
#  user_id_dealing_with_vetting                :integer
#  number_of_days_for_vetting                  :integer
#  original_external_deadline                  :date
#  original_internal_deadline                  :date
#  num_days_late_against_original_deadline     :integer
#  request_method                              :string
#  sent_to_sscl                                :date
#  rejected                                    :string           default("No")
#  case_originally_rejected                    :string
#  other_rejected_reason                       :string
#  rejected_reasons                            :json
#
require "rails_helper"

RSpec.describe ::Warehouse::CaseReport, type: :model do
  # Note mix of closed and open cases as Warehouse::CaseReport is not
  # restricted to only open or closed cases
  let(:kases) do
    [
      create(:closed_case, :fully_refused_exempt_s40, :extended_for_pit),
      create(:sar_case, :extended_deadline_sar),
      create(:offender_sar_case, :third_party),
      create(:offender_sar_case, :rejected),
      create(:ico_foi_case),
      create(:accepted_ico_sar_case),
      create(:awaiting_responder_ot_ico_foi),
      create(:overturned_ico_sar, :flagged),
    ]
  end

  describe "#has_one case" do
    it "belongs to a case" do
      kase = create(:accepted_sar)
      kase.warehouse_case_report = described_class.generate(kase)
      kase.reload
      expect(kase.warehouse_case_report.case).to eq kase
    end
  end

  describe "#for" do
    it "creates a new CaseReport if none exists" do
      kase = create :accepted_sar
      expect(kase.warehouse_case_report).to be_nil

      case_report = described_class.for(kase)
      expect(case_report.new_record?).to be true
    end

    it "returns existing CaseReport if it exists" do
      kase = create :accepted_sar
      expect(kase.warehouse_case_report).to be_nil
      described_class.generate(kase)
      kase.reload

      case_report = described_class.for(kase)
      expect(case_report.new_record?).to be false
    end
  end

  describe "#generate" do
    it "sets correct CaseReport fields for a new Case::Base" do
      # For new Case::Base
      kases.each do |kase|
        expect(kase.warehouse_case_report).to be_nil
        compare_output(kase)
      end
    end

    it "handles a race condition when a new case is updated straight away" do
      kase = create(:accepted_sar)
      Warehouse::CaseReport.generate(kase)
      kase.warehouse_case_report = nil # mimic the case object not being updated with the associated warehouse case report
      expect {
        Warehouse::CaseReport.generate(kase)
      }.not_to raise_error
    end
  end

  describe "#generate_all" do
    it "generates CaseReport for all existing Case::Base" do
      kases
      num_cases = Case::Base.all.size
      expect(num_cases).to be > 0
      expect(described_class.generate_all).to eq num_cases
    end
  end

  describe "#reconcile" do
    it "returns a tuple of number of processed missing and deleted cases" do
      expect(described_class.reconcile).to eq [0, 0]
    end
  end

  describe "#reconcile_missing_cases" do
    it "reconciles all undeleted missing cases" do
      new_kases = [create(:closed_case), create(:closed_sar)]
      expect(new_kases.all? { |k| k.warehouse_case_report.present? }).to be false

      described_class.reconcile_missing_cases
      expect(new_kases.all? { |k| k.reload.warehouse_case_report.present? }).to be true
    end

    it "does not reconcile deleted cases" do
      kase = create(:closed_case)
      case_id = kase.id
      expect(kase.warehouse_case_report).to be_nil

      kase.update!(deleted: true, reason_for_deletion: "some reason")

      described_class.reconcile_missing_cases
      expect(described_class.find_by(case_id:)).to be_nil
    end
  end

  # Case::Base destroys dependent CaseReport, however #reconcile_deleted_cases
  # provides a utility method to ensure there is no data inconsistency e.g.
  # due to manual database manipulation during testing
  describe "#reconcile_deleted_cases" do
    it "deletes CaseReport for deleted Case::Base" do
      undeleted_kase = create(:closed_case)
      deleted_kase = create(:closed_case)
      deleted_case_id = deleted_kase.id # Remember the ID

      [undeleted_kase, deleted_kase]
        .each { |kase| described_class.generate(kase) }
        .each { |kase| expect(kase.reload.warehouse_case_report).not_to be_nil }

      # Switch off PostgreSQL foreign key constraints
      ActiveRecord::Base.connection.execute("ALTER TABLE #{Case::Base.table_name} DISABLE TRIGGER ALL;")

      deleted_kase.delete # No callbacks executed, inc. dependent: destroy
      expect(described_class.find_by(case_id: deleted_case_id)).not_to be_nil

      described_class.reconcile_deleted_cases
      expect(described_class.find_by(case_id: deleted_case_id)).to be_nil
      expect(described_class.find_by(case_id: undeleted_kase.id)).not_to be_nil

      ActiveRecord::Base.connection.execute("ALTER TABLE #{Case::Base.table_name} ENABLE TRIGGER ALL;")
    end
  end

  describe "#process_cases" do
    it "accepts an ActiveRecord Query" do
      expect { described_class.process_cases("bad param") }.to raise_error NoMethodError, /undefined method `in_batches' for an instance of String/
    end

    it "returns the number of CaseReport (re)generated" do
      expect(described_class.process_cases(Case::Base.all, throttle: false)).to eq 0

      create :overturned_ico_sar # Creates 3 cases
      expect(described_class.process_cases(Case::Base.all, throttle: false)).to eq 3
    end

    it "throttles the processing by 10 seconds" do
      started = Time.zone.now
      create :foi_case
      expect(Case::Base.all.size).to eq 1 # Ensure just 1 batch is processed
      described_class.process_cases(Case::Base.all, throttle: true)
      time_taken = (Time.zone.now.to_f - started.to_f).to_f

      expect(time_taken).to be >= 10.0 # seconds to wait before next batch
    end
  end

  describe "#rejected_reasons_selection" do
    it "returns hash with selection" do
      rejected_case = create(:offender_sar_case, :rejected)
      expect(described_class.rejected_reasons_selection(rejected_case)).to match({ "cctv_bwcf" => "No",
                                                                                   "change_of_name_certificate" => "No",
                                                                                   "court_data_request" => "Yes",
                                                                                   "data_previously_requested" => "No",
                                                                                   "further_identification" => "Yes",
                                                                                   "identification_for_ex_inmate_probation" => "No",
                                                                                   "illegible_handwriting_unreadable_content" => "No",
                                                                                   "id_required" => "No",
                                                                                   "invalid_authority" => "No",
                                                                                   "medical_data" => "No",
                                                                                   "observation_book_entries" => "No",
                                                                                   "police_data" => "No",
                                                                                   "social_services_data" => "No",
                                                                                   "telephone_recordings_logs" => "No",
                                                                                   "telephone_transcripts" => "No",
                                                                                   "third_party_identification" => "No",
                                                                                   "what_data_no_data_requested" => "No",
                                                                                   "other" => "No" })
    end
  end

  def compare_closuredetails(kase, result, case_report)
    if kase.ico?
      original_case_csv_row = CSVExporter.new(kase.original_case).to_csv
      original_case_result = CSVExporter::CSV_COLUMN_HEADINGS.zip(original_case_csv_row).to_h
      expect(original_case_result["Info held"]).to eq case_report.info_held
      expect(original_case_result["Outcome"]).to eq case_report.outcome
      expect(original_case_result["Refusal reason"]).to eq case_report.refusal_reason
      expect(original_case_result["Exemptions"]).to eq case_report.exemptions
      expect(case_report.appeal_outcome).to eq kase.decorate.pretty_ico_decision
    else
      expect(result["Info held"]).to eq case_report.info_held
      expect(result["Outcome"]).to eq case_report.outcome
      expect(result["Refusal reason"]).to eq case_report.refusal_reason
      expect(result["Exemptions"]).to eq case_report.exemptions
      expect(result["Appeal outcome"]).to eq case_report.appeal_outcome
    end
  end

  # Compares CSVExporter output with CaseReport output
  def compare_output(kase)
    Timecop.freeze Time.zone.local(2018, 10, 1, 13, 21, 33) do
      csv_row = CSVExporter.new(kase).to_csv
      result = CSVExporter::CSV_COLUMN_HEADINGS.zip(csv_row).to_h
      case_report = described_class.generate(kase)

      expect(result["Number"]).to eq case_report.number
      expect(result["Case type"]).to eq case_report.case_type
      expect(result["Current state"]).to eq case_report.current_state
      expect(result["Responding team"]).to eq case_report.responding_team
      expect(result["Responder"]).to eq case_report.responder
      expect(result["Date compliant draft uploaded"]).to eq case_report.date_compliant_draft_uploaded
      expect(result["Trigger"]).to eq case_report.trigger
      expect(result["Name"]).to eq case_report.name
      expect(result["Requester type"]).to eq case_report.requester_type
      expect(result["Message"]).to eq case_report.message

      compare_closuredetails(kase, result, case_report)

      expect(result["Postal address"]).to eq case_report.postal_address
      expect(result["Email"]).to eq case_report.email
      expect(result["Third party"]).to eq case_report.third_party
      expect(result["Reply method"]).to eq case_report.reply_method
      expect(result["SAR Subject type"]).to eq case_report.sar_subject_type
      expect(result["SAR Subject full name"]).to eq case_report.sar_subject_full_name
      expect(result["Business unit responsible for late response"]).to eq case_report.business_unit_responsible_for_late_response
      expect(result["Extended"]).to eq case_report.extended
      expect(result["Extension Count"]).to eq case_report.extension_count
      expect(result["Deletion Reason"]).to eq case_report.deletion_reason
      expect(result["Casework officer"]).to eq case_report.casework_officer
      expect(result["Created by"]).to eq case_report.created_by
      expect(result["Business group"]).to eq case_report.business_group
      expect(result["Directorate name"]).to eq case_report.directorate_name
      expect(result["Director General name"]).to eq case_report.director_general_name
      expect(result["Director name"]).to eq case_report.director_name
      expect(result["Deputy Director name"]).to eq case_report.deputy_director_name
      expect(result["Draft in time"]).to eq case_report.draft_in_time
      expect(result["In target"]).to eq case_report.in_target
      expect(result["Number of days late"]).to eq case_report.number_of_days_late
      expect(result["Days taken (FOIs, IRs, ICO appeals = working days; SARs = calendar days)"]).to eq case_report.number_of_days_taken
      expect(result["Number of days taken after extension"]).to eq case_report.number_of_days_taken_after_extension

      # CSV exporter outputs dates as strings whereas
      # CaseReport stores actual Date objects
      expect(result["Date received"]).to eq case_report.date_received&.strftime("%F")
      expect(result["Internal deadline"]).to eq case_report.internal_deadline&.strftime("%F")
      expect(result["External deadline"]).to eq case_report.external_deadline&.strftime("%F")
      expect(result["Date responded"]).to eq case_report.date_responded&.strftime("%F")
      expect(result["Date created"]).to eq case_report.date_created&.strftime("%F")

      expect(result["Original internal deadline"]).to eq case_report.original_internal_deadline
      expect(result["Original external deadline"]).to eq case_report.original_external_deadline
      expect(result["Number of days late against original deadline"]).to eq case_report.num_days_late_against_original_deadline
    end
  end
end
