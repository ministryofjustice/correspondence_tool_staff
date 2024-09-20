require "rails_helper"

describe Stats::Warehouse::CaseReportSync do
  include ActiveJob::TestHelper

  describe "#initialize" do
    it "requires a warehousable ActiveRecord instance" do
      not_activerecord = String.new
      warehousable = User.new

      expect(described_class.new(warehousable)).to be_kind_of described_class
      expect { described_class.new(not_activerecord) }.to raise_error ArgumentError
    end
  end

  describe ".affected_cases" do
    it "returns the result of the execute function" do
      record = Object.new
      kase = create :foi_case

      setting = {
        fields: %w[fake useless],
        execute: ->(_record, _query) { [kase] },
      }

      expect(described_class.affected_cases(record, setting)).to eq [kase]
    end
  end

  describe ".sync" do
    let(:kase) { create :foi_case }

    context "with a Case::Base" do
      it "calls generate" do
        expect(::Warehouse::CaseReport).to receive(:generate).with(kase)
        described_class.sync(kase)
      end
    end

    context "with a different type of object" do
      it "does nothing" do
        expect(::Warehouse::CaseReport).not_to receive(:generate)
        described_class.sync(Object.new)
      end
    end
  end

  describe ".find_cases" do
    it "creates a job for every case related to update object" do
      user = create(:foi_responder)
      records = create_list(:foi_case, 3, creator: user)

      records.each do |record|
        ::Warehouse::CaseReport.generate(record)
        expect(::Warehouse::CaseSyncJob).to receive(:perform_later).with("Case::Base", record.id)
      end

      query = "creator_id = :param"
      described_class.find_cases(user, query)
    end
  end

  describe ".syncable?" do
    let(:tuple) { described_class.syncable?(Object.new) }

    it "returns a tuple" do
      expect(tuple).to be_a Array
      expect(tuple.size).to eq 2
    end

    it "returns true or false in position 1 if syncable" do
      expect(tuple[0]).to be_in([true, false])
    end

    it "returns the matching MAPPING class in position 2 if syncable" do
      # Negative
      expect(described_class.syncable?(Feedback.new)[1]).to be nil

      # Positive
      expect(described_class.syncable?(User.new)[1]).to eq :User
      expect(described_class.syncable?(Case::SAR::Offender.new)[1]).to eq :'Case::Base'
    end
  end

  describe "::MAPPINGS" do
    let(:syncable_klass_names) do
      %i[
        Assignment
        Case::Base
        CaseClosure::Metadatum
        CaseTransition
        Team
        TeamProperty
        User
      ]
    end

    it "specifies the source of data for a CaseReport" do
      expect(described_class::MAPPINGS.keys.sort).to eq syncable_klass_names
    end

    it "has settings per source class to allow affected Cases to be found" do
      described_class::MAPPINGS.each do |_klass_name, settings|
        # The fields in Warehouse::CaseReport that are sourced from klass_name
        expect(settings[:fields]).to be_a Array

        # Function that returns an Array of Case::Base when executed
        expect(settings[:execute]).to respond_to :call
      end
    end

    describe "execute:" do
      describe "Case::Base" do
        it "returns the given case" do
          record = create :sar_case
          query = "case_id = -11 OR name = 'this is an ignored where clause'"

          function = described_class::MAPPINGS[:'Case::Base'][:execute]
          result = function.call(record, query)
          expect(result).to eq record
        end
      end
    end
  end

  describe "CaseReport updated when" do
    describe "Case::Base" do
      let(:kase) { create :sar_case }
      let(:warehouse_case_report) { kase.reload.warehouse_case_report }

      before do
        ::Warehouse::CaseReport.generate(kase)
        kase.reload
      end

      it "updates related CaseReport" do
        new_name = "Tiny Temporary #{rand(20)}"
        kase.update!(name: new_name)
        described_class.new(kase) # re-generate CaseReport
        expect(warehouse_case_report.name).to eq new_name
      end
    end

    describe "CaseClosure::Metadatum" do
      # Current Metadatum based closure information
      let(:info_held_status_case) { create :closed_case, :granted_in_full }
      let(:refusal_reason_case) { create :closed_case, :other_vexatious }
      let(:outcome_case) { create :closed_case }
      let(:appeal_outcome_case) do
        kase = create :closed_case
        appeal_outcome = CaseClosure::AppealOutcome.find_or_create_by!(
          subtype: nil,
          name: "Upheld",
          abbreviation: "upheld",
          sequence_id: 40,
        )
        kase.appeal_outcome_id = appeal_outcome.id
        kase.save!
        kase
      end

      # Utility variables
      let(:all_cases) do
        [
          info_held_status_case,
          refusal_reason_case,
          outcome_case,
          appeal_outcome_case,
        ]
      end
      let(:metadatum) do
        [
          info_held_status_case.info_held_status,
          refusal_reason_case.refusal_reason,
          outcome_case.outcome,
          appeal_outcome_case.appeal_outcome,
        ]
      end
      let(:new_name) { "Tronald Dump" }

      before do
        all = all_cases.map do |kase|
          ::Warehouse::CaseReport.generate(kase)
          kase.reload
        end

        all.each do |kase|
          expect(kase.warehouse_case_report).to be_present # rubocop:disable RSpec/ExpectInHook
        end
      end

      it "updates related CaseReport" do
        metadatum.each do |metdata|
          metdata.update!(name: new_name)
          described_class.new(metdata) # re-generate related CaseReports
        end

        perform_enqueued_jobs

        all_cases.each(&:reload)

        expect(info_held_status_case.warehouse_case_report.info_held).to eq new_name
        expect(refusal_reason_case.warehouse_case_report.refusal_reason).to eq new_name
        expect(outcome_case.warehouse_case_report.outcome).to eq new_name
        expect(appeal_outcome_case.warehouse_case_report.appeal_outcome).to eq new_name
      end
    end

    describe "Team" do
      let(:responded_case) { create :responded_foi_case }
      let(:responding_team) { responded_case.responding_team }
      let(:new_team_name) { Faker::Company.name }

      before do
        ::Warehouse::CaseReport.generate(responded_case)
      end

      it "updates related CaseReport fields" do
        expect(responded_case.reload.warehouse_case_report).to be_present

        affected_case_relationships = [
          responding_team, # Maps to CaseReport#responding_team
          responding_team.business_group, # Maps CaseReport#business_group
          responding_team.directorate, # Maps to CaseReport#directorate_name
        ]

        affected_case_relationships.each do |team|
          team.update!(name: new_team_name)
          described_class.new(responded_case) # re-generate CaseReport
        end

        warehouse_case_report = responded_case.reload.warehouse_case_report

        expect(warehouse_case_report.responding_team).to eq new_team_name
        expect(warehouse_case_report.business_group).to eq new_team_name
        expect(warehouse_case_report.directorate_name).to eq new_team_name
      end
    end

    describe "TeamProperty" do
      let(:responded_case) { create :responded_foi_case }
      let(:responding_team) { responded_case.responding_team }
      let(:new_name) { "Donald Druck #{rand(20)}" }

      # {
      #   CaseReport#field_name: {
      #     property: team 'lead' row from TeamProperty,
      #     kase: Case::Base the team/property affects
      #   }
      # }
      let(:case_report_source_fields) do
        {
          director_general_name: {
            property: responding_team.business_group.properties.lead.singular_or_nil,
            kase: responded_case,
          },
          director_name: {
            property: responding_team.directorate.properties.lead.singular_or_nil,
            kase: responded_case,
          },
          deputy_director_name: {
            property: responding_team.properties.lead.singular_or_nil,
            kase: responded_case,
          },
        }
      end

      it "updates related CaseReport fields" do
        case_report_source_fields.each do |case_report_field, source|
          kase = source[:kase]

          ::Warehouse::CaseReport.generate(kase)
          expect(kase.reload.warehouse_case_report).to be_present
          property = source[:property]

          property.update!(value: new_name)
          described_class.new(property) # re-sync

          perform_enqueued_jobs

          warehouse_case_report = kase.reload.warehouse_case_report
          expect(warehouse_case_report.send(case_report_field)).to eq new_name
        end
      end
    end

    describe "User" do
      # {
      #   CaseReport#field_name: {
      #     field: Case::Base source field,
      #     kase: Instance of Case::Base possessing the source field
      #   }
      # }
      let(:case_report_source_fields) do
        {
          created_by: {
            field: :creator,
            kase: create(:foi_case),
          },
          casework_officer: {
            field: :casework_officer_user,
            kase: create(:case, :flagged_accepted),
          },
          responder: {
            field: :responder,
            kase: create(:responded_case),
          },
        }
      end

      it "updates related CaseReport fields" do
        new_name = "Andy Kind Esquire#{rand(20)}"

        case_report_source_fields.each do |case_report_field, source|
          source_field = source[:field]
          kase = source[:kase]

          ::Warehouse::CaseReport.generate(kase)
          expect(kase.reload.warehouse_case_report).to be_present
          user = kase.send(source_field)

          user.update!(full_name: new_name)
          described_class.new(user) # re-sync

          perform_enqueued_jobs

          warehouse_case_report = kase.reload.warehouse_case_report
          expect(warehouse_case_report.send(case_report_field)).to eq new_name
        end
      end
    end
  end
end
