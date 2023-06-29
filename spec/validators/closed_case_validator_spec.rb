require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
describe "ClosedCaseValidator" do
  before(:all) do
    require Rails.root.join("db/seeders/case_closure_metadata_seeder")
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) { CaseClosure::MetadataSeeder.unseed! }

  context "when preparing for close validations" do
    let(:kase) { create :case, date_responded: Time.zone.today }

    before { kase.prepare_for_close }

    describe "validate_late_team_id" do
      before do
        kase.outcome = CaseClosure::Outcome.granted
        kase.info_held_status = CaseClosure::InfoHeldStatus.part_held
      end

      context "when late_team_id is blank" do
        it "does not error if case is responded in time" do
          allow(kase).to receive(:responded_late?).and_return(false)
          kase.late_team_id = nil
          expect(kase).to be_valid
        end

        it "errors if case is late" do
          allow(kase).to receive(:responded_late?).and_return(true)
          kase.late_team_id = nil
          expect(kase).not_to be_valid
          expect(kase.errors[:late_team_id]).to eq %w[blank_invalid_if_case_late]
        end
      end

      context "when late_team_id is not blank" do
        it "is valid" do
          allow(kase).to receive(:responded_late?).and_return(true)
          kase.late_team_id = BusinessUnit.first.id
          expect(kase).to be_valid
        end
      end
    end

    describe "date responded validation" do
      before do
        kase.outcome = CaseClosure::Outcome.granted
        kase.info_held_status = CaseClosure::InfoHeldStatus.part_held
      end

      it "errors if date_responded blank" do
        kase.date_responded = nil
        expect(kase).not_to be_valid
        expect(kase.errors[:date_responded]).to eq(["cannot be blank"])
      end

      it "errors if date_responded in the future" do
        kase.date_responded = 3.days.from_now
        expect(kase).not_to be_valid
        expect(kase.errors[:date_responded]).to eq(["cannot be in the future"])
      end

      it "errors if date before received date" do
        kase.date_responded = kase.received_date - 1.day
        expect(kase).not_to be_valid
        expect(kase.errors[:date_responded]).to eq(["cannot be before date received"])
      end

      it "does not error if between received date and today" do
        kase.date_responded = kase.received_date
        expect(kase).to be_valid
      end
    end

    context "when info held in full" do
      before { kase.info_held_status = CaseClosure::InfoHeldStatus.held }

      context "when granted in full" do
        before { kase.outcome = CaseClosure::Outcome.granted }

        context "when no refusal reason or exemptions" do
          it "is valid" do
            kase.refusal_reason = nil
            kase.exemptions = []
            expect(kase).to be_valid
          end
        end

        context "when refusal reason supplied" do
          it "is not valid" do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context "when exemption supplied" do
          it "is not valid" do
            kase.exemptions = [CaseClosure::Exemption.s27]
            expect(kase).not_to be_valid
            expect(kase.errors[:exemptions]).to eq ["cannot be present unless case was fully or partly refused, or information held not confirmed and NCND"]
          end
        end
      end

      context "when refused in part" do
        before  { kase.outcome = CaseClosure::Outcome.part_refused }

        context "when refusal reason supplied" do
          it "is not valid" do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context "when no refusal reason supplied" do
          before { kase.refusal_reason = nil }

          context "when at least one exemption supplied" do
            it "is valid" do
              kase.exemptions = [CaseClosure::Exemption.s27]
              expect(kase).to be_valid
            end
          end

          context "when multiple exemptions supplied" do
            it "is valid" do
              kase.exemptions = [CaseClosure::Exemption.s27, CaseClosure::Exemption.s35]
              expect(kase).to be_valid
            end
          end

          context "when no exemptions supplied" do
            it "is not valid" do
              kase.exemptions = []
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ["must be specified for this outcome"]
            end
          end

          context "when cost exemption is supplied" do
            it "is invalid" do
              kase.exemptions = [CaseClosure::Exemption.s12]
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ["cost is not valid for part refusals"]
            end
          end
        end
      end

      context "when refused in full" do
        before  { kase.outcome = CaseClosure::Outcome.fully_refused }

        context "when refusal reason supplied" do
          it "is not valid" do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context "when no refusal reason supplied" do
          before { kase.refusal_reason = nil }

          context "when at least one exemption supplied" do
            it "is valid" do
              kase.exemptions = [CaseClosure::Exemption.s27]
              expect(kase).to be_valid
            end
          end

          context "when multiple exemptions supplied" do
            it "is valid" do
              kase.exemptions = [CaseClosure::Exemption.s27, CaseClosure::Exemption.s35]
              expect(kase).to be_valid
            end
          end

          context "when no exemptions supplied" do
            it "is not valid" do
              kase.exemptions = []
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ["must be specified for this outcome"]
            end
          end

          context "when exemption cost" do
            it "is valid" do
              kase.exemptions = [CaseClosure::Exemption.s12]
              expect(kase).to be_valid
            end
          end
        end
      end
    end

    context "when info held in part" do
      before { kase.info_held_status = CaseClosure::InfoHeldStatus.part_held }

      context "when granted in full" do
        before { kase.outcome = CaseClosure::Outcome.granted }

        context "when no refusal reason or exemptions" do
          it "is valid" do
            kase.refusal_reason = nil
            kase.exemptions = []
            expect(kase).to be_valid
          end
        end

        context "when refusal reason supplied" do
          it "is not valid" do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context "when exemption supplied" do
          it "is not valid" do
            kase.exemptions = [CaseClosure::Exemption.s27]
            expect(kase).not_to be_valid
            expect(kase.errors[:exemptions]).to eq ["cannot be present unless case was fully or partly refused, or information held not confirmed and NCND"]
          end
        end
      end

      context "when refused in part" do
        before  { kase.outcome = CaseClosure::Outcome.part_refused }

        context "when refusal reason supplied" do
          it "is not valid" do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context "when no refusal reason supplied" do
          before { kase.refusal_reason = nil }

          context "when at least one exemption supplied" do
            it "is valid" do
              kase.exemptions = [CaseClosure::Exemption.s27]
              expect(kase).to be_valid
            end
          end

          context "when multiple exemptions supplied" do
            it "is valid" do
              kase.exemptions = [CaseClosure::Exemption.s27, CaseClosure::Exemption.s35]
              expect(kase).to be_valid
            end
          end

          context "when no exemptions supplied" do
            it "is not valid" do
              kase.exemptions = []
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ["must be specified for this outcome"]
            end
          end

          context "when cost exemption is supplied" do
            it "is invalid" do
              kase.exemptions = [CaseClosure::Exemption.s12]
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ["cost is not valid for part refusals"]
            end
          end
        end
      end

      context "when refused in full" do
        before  { kase.outcome = CaseClosure::Outcome.fully_refused }

        context "when refusal reason supplied" do
          it "is not valid" do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context "when no refusal reason supplied" do
          before { kase.refusal_reason = nil }

          context "and at least one exemption supplied" do
            it "is valid" do
              kase.exemptions = [CaseClosure::Exemption.s27]
              expect(kase).to be_valid
            end
          end

          context "when multiple exemptions supplied" do
            it "is valid" do
              kase.exemptions = [CaseClosure::Exemption.s27, CaseClosure::Exemption.s35]
              expect(kase).to be_valid
            end
          end

          context "when no exemptions supplied" do
            it "is not valid" do
              kase.exemptions = []
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ["must be specified for this outcome"]
            end
          end

          context "when exemption cost" do
            it "is valid" do
              kase.exemptions = [CaseClosure::Exemption.s12]
              expect(kase).to be_valid
            end
          end
        end
      end
    end

    context "when info not held" do
      before do
        kase.info_held_status = CaseClosure::InfoHeldStatus.not_held
        kase.refusal_reason = nil
        kase.outcome = nil
        kase.exemptions = []
      end

      context "when no refusal reason" do
        it "is valid" do
          expect(kase).to be_valid
        end
      end

      context "when refusal reason present" do
        it "is invalid" do
          kase.refusal_reason = CaseClosure::RefusalReason.vex
          expect(kase).not_to be_valid
          expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
        end
      end

      context "when outcome present" do
        it "is invalid" do
          kase.outcome = CaseClosure::Outcome.first
          expect(kase).not_to be_valid
          expect(kase.errors[:outcome]).to eq ["can only be present if information held or part held"]
        end
      end

      context "when exemptions present" do
        it "is invalid" do
          kase.exemptions = [CaseClosure::Exemption.first]
          expect(kase).not_to be_valid
          expect(kase.errors[:exemptions]).to eq ["cannot be present unless case was fully or partly refused, or information held not confirmed and NCND"]
        end
      end
    end

    context "when info not confirmed (a.k.a Other)" do
      before do
        kase.info_held_status = CaseClosure::InfoHeldStatus.not_confirmed
        kase.outcome = nil
        kase.refusal_reason = CaseClosure::RefusalReason.first
      end

      context "when refusal reason present, exemption present, but no outcome or refusal reason" do
        it "is invalid" do
          expect(kase).to be_valid
        end
      end

      context "when no refusal reason present" do
        it "is not valid" do
          kase.refusal_reason = nil
          expect(kase).not_to be_valid
          expect(kase.errors[:refusal_reason]).to eq ["must be present for the specified outcome"]
        end
      end

      context "when outcome present" do
        it "is invalid" do
          kase.outcome = CaseClosure::Outcome.first
          expect(kase).not_to be_valid
          expect(kase.errors[:outcome]).to eq ["can only be present if information held or part held"]
        end
      end

      context "when exemptions not present" do
        it "is is valid" do
          kase.exemptions = []
          expect(kase).to be_valid
        end
      end

      context "when exemption present" do
        it "is not valid" do
          kase.exemptions = [CaseClosure::Exemption.s12]
          expect(kase).not_to be_valid
          expect(kase.errors[:exemptions]).to eq ["cannot be present unless case was fully or partly refused, or information held not confirmed and NCND"]
        end
      end

      context "when refusal reason is NCND" do
        context "and no exemption present" do
          it "is not valid" do
            kase.refusal_reason = CaseClosure::RefusalReason.ncnd
            expect(kase).not_to be_valid
            expect(kase.errors[:exemptions]).to eq ["must be specified for this outcome"]
          end
        end

        context "with an exemption" do
          it "is valid" do
            kase.refusal_reason = CaseClosure::RefusalReason.ncnd
            kase.exemptions = [CaseClosure::Exemption.first]
            expect(kase).to be_valid
          end
        end
      end
    end
  end

  describe "ICO Appeal cases" do
    let(:responded_ico) { build :responded_ico_foi_case }

    before do
      responded_ico.prepare_for_close
    end

    context "and ico_decision" do
      before do
        responded_ico.update(
          date_ico_decision_received: Time.zone.today,
          ico_decision: "upheld",
          uploaded_ico_decision_files: %w[file_1 file2],
        )
      end

      context "and blank" do
        it "is invalid" do
          responded_ico.ico_decision = nil
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:ico_decision]).to eq %w[blank]
        end
      end

      context "and just right" do
        it "is valid" do
          expect(responded_ico).to be_valid
        end
      end
    end

    context "when date_ico_decision_received" do
      before do
        responded_ico.ico_decision = "upheld"
        responded_ico.uploaded_ico_decision_files = %w[file_1 file2]
      end

      context "and blank" do
        it "is invalid" do
          responded_ico.date_ico_decision_received = nil
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:date_ico_decision_received]).to eq ["cannot be blank"]
        end
      end

      context "and future" do
        it "is invalid" do
          responded_ico.date_ico_decision_received = Time.zone.tomorrow
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:date_ico_decision_received]).to eq %w[future]
        end
      end

      context "and too far in the past" do
        it "is invalid" do
          responded_ico.date_ico_decision_received = responded_ico.created_at - 1.day
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:date_ico_decision_received]).to eq ["before creation date"]
        end
      end

      context "and just right" do
        context "and yesterday" do
          it "is valid" do
            responded_ico.date_ico_decision_received = Time.zone.yesterday
            expect(responded_ico).to be_valid
          end
        end

        context "and creation date" do
          it "is valid" do
            responded_ico.date_ico_decision_received = responded_ico.created_at.to_date
            expect(responded_ico).to be_valid
          end
        end
      end
    end

    context "when uploaded ico decision files" do
      before do
        responded_ico.date_ico_decision_received = Time.zone.today
        responded_ico.uploaded_ico_decision_files = nil
        responded_ico.ico_decision_comment = nil
      end

      context "when decision upheld" do
        before do
          responded_ico.ico_decision = "upheld"
        end

        context "when files and decision blank" do
          it "is not valid" do
            expect(responded_ico).not_to be_valid
          end
        end

        context "when files uploaded" do
          it "is valid" do
            responded_ico.uploaded_ico_decision_files = %w[file_1 file2]
            expect(responded_ico).to be_valid
          end
        end
      end

      context "when decision overturned" do
        before do
          responded_ico.ico_decision = "overturned"
        end

        context "when uploaded ico decision files blank" do
          it "is invalid" do
            expect(responded_ico).not_to be_valid
            expect(responded_ico.errors[:uploaded_ico_decision_files]).to eq ["No ICO decision files have been uploaded"]
          end
        end

        context "when files uploaded" do
          it "is valid" do
            responded_ico.uploaded_ico_decision_files = %w[file_1 file2]
            expect(responded_ico).to be_valid
          end
        end
      end
    end
  end

  describe "SAR IR cases" do
    let!(:sar_ir) { create(:ready_to_close_sar_internal_review) }
    let(:outcome_reason_ids) { CaseClosure::OutcomeReason.all.map(&:id) }

    before do
      sar_ir.prepare_for_close
    end

    describe "#validate_sar_ir_outcome" do
      context "when sar_ir_outcome blank" do
        it "has correct error" do
          sar_ir.valid?
          expect(sar_ir.errors[:sar_ir_outcome]).to eq ["must be selected"]
        end
      end

      context "when sar_ir_outcome present" do
        it "has no errors" do
          sar_ir.sar_ir_outcome = "Upheld"
          sar_ir.valid?
          expect(sar_ir.errors[:sar_ir_outcome]).to eq []
        end
      end
    end

    describe "#validate_outcome_reasons" do
      context "when outcome reasons blank" do
        it "has correct error" do
          sar_ir.sar_ir_outcome = "Upheld in part"
          sar_ir.valid?
          expect(sar_ir.errors[:outcome_reasons]).to eq ["must be selected"]
        end
      end

      context "when ourcome reasons present" do
        it "has no errors" do
          sar_ir.sar_ir_outcome = "Upheld in part"
          sar_ir.outcome_reason_ids = outcome_reason_ids
          sar_ir.valid?
          expect(sar_ir.errors[:outcome_reasons]).to eq []
        end
      end
    end

    describe "#validate_team_responsible" do
      context "when team responsible blank" do
        it "has correct error" do
          sar_ir.sar_ir_outcome = "Upheld in part"
          sar_ir.valid?
          expect(sar_ir.errors[:team_responsible_for_outcome_id]).to eq ["must be selected"]
        end
      end

      context "when team responsible present" do
        it "has no errors" do
          sar_ir.sar_ir_outcome = "Upheld in part"
          sar_ir.team_responsible_for_outcome_id = 1
          sar_ir.valid?
          expect(sar_ir.errors[:team_responsible_for_outcome_id]).to eq []
        end
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
