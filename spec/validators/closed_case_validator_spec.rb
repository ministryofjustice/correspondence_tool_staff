require 'rails_helper'

describe 'ClosedCaseValidator' do

  before(:all) do
    require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) { CaseClosure::Metadatum.destroy_all }

  context 'preparing for close validations' do

    let(:kase) { create :case, date_responded: Date.today }


    before(:each) { kase.prepare_for_close }

    describe 'validate_late_team_id' do

      before(:each) do
        kase.outcome = CaseClosure::Outcome.granted
        kase.info_held_status = CaseClosure::InfoHeldStatus.part_held
      end

      context 'late_team_id is blank' do
        it 'does not error if case is responded in time' do
          allow(kase).to receive(:responded_late?).and_return(false)
          kase.late_team_id = nil
          expect(kase).to be_valid
        end

        it 'errors if case is late' do
          allow(kase).to receive(:responded_late?).and_return(true)
          kase.late_team_id = nil
          expect(kase).not_to be_valid
          expect(kase.errors[:late_team_id]).to eq ['blank_invalid_if_case_late']
        end
      end

      context 'late_team_id is not blank' do
        it 'is valid' do
          allow(kase).to receive(:responded_late?).and_return(true)
          kase.late_team_id = BusinessUnit.first.id
          expect(kase).to be_valid
        end
      end
    end

    describe 'date responded validation' do

      before(:each) do
        kase.outcome = CaseClosure::Outcome.granted
        kase.info_held_status = CaseClosure::InfoHeldStatus.part_held
      end

      it 'errors if date_responded blank' do
        kase.date_responded = nil
        expect(kase).not_to be_valid
        expect(kase.errors[:date_responded]).to eq(["cannot be blank"])
      end

      it 'errors if date_responded in the future' do
        kase.date_responded = 3.days.from_now
        expect(kase).not_to be_valid
        expect(kase.errors[:date_responded]).to eq(["cannot be in the future"])
      end

      it 'errors if date before received date' do
        kase.date_responded = kase.received_date - 1.day
        expect(kase).not_to be_valid
        expect(kase.errors[:date_responded]).to eq(["cannot be before date received"])
      end

      it 'does not error if between received date and today' do
        kase.date_responded = kase.received_date
        expect(kase).to be_valid
      end
    end

    context 'Info Held in full' do

      before(:each) { kase.info_held_status = CaseClosure::InfoHeldStatus.held }

      context 'Granted in full' do
        before(:each) { kase.outcome = CaseClosure::Outcome.granted }

        context 'no refusal reason or exemptions' do
          it 'is valid' do
            kase.refusal_reason = nil
            kase.exemptions = []
            expect(kase).to be_valid
          end
        end

        context 'refusal reason supplied' do
          it 'is not valid' do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context 'exemption supplied' do
          it 'is not valid' do
            kase.exemptions = [ CaseClosure::Exemption.s27 ]
            expect(kase).not_to be_valid
            expect(kase.errors[:exemptions]).to eq ['cannot be present unless case was fully or partly refused, or information held not confirmed and NCND']
          end
        end
      end

      context 'Refused in part' do
        before(:each)  { kase.outcome = CaseClosure::Outcome.part_refused }

        context 'refusal reason supplied' do
          it 'is not valid' do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context 'no refusal reason supplied' do
          before(:each) { kase.refusal_reason = nil }

          context 'at least one exemption supplied' do
            it 'is valid' do
              kase.exemptions = [ CaseClosure::Exemption.s27 ]
              expect(kase).to be_valid
            end
          end

          context 'multiple exemptions supplied' do
            it 'is valid' do
              kase.exemptions = [ CaseClosure::Exemption.s27, CaseClosure::Exemption.s35 ]
              expect(kase).to be_valid
            end
          end

          context 'no exemptions supplied' do
            it 'is not valid' do
              kase.exemptions = []
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ['must be specified for this outcome']
            end
          end

          context 'cost exemption is supplied' do
            it 'is invalid' do
              kase.exemptions = [ CaseClosure::Exemption.s12 ]
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ['cost is not valid for part refusals']
            end
          end
        end
      end

      context 'Refused in full' do
        before(:each)  { kase.outcome = CaseClosure::Outcome.fully_refused }

        context 'refusal reason supplied' do
          it 'is not valid' do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context 'no refusal reason supplied' do
          before(:each) { kase.refusal_reason = nil }

          context 'at least one exemption supplied' do
            it 'is valid' do
              kase.exemptions = [ CaseClosure::Exemption.s27 ]
              expect(kase).to be_valid
            end
          end

          context 'multiple exemptions supplied' do
            it 'is valid' do
              kase.exemptions = [ CaseClosure::Exemption.s27, CaseClosure::Exemption.s35 ]
              expect(kase).to be_valid
            end
          end

          context 'no exemptions supplied' do
            it 'is not valid' do
              kase.exemptions = []
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ['must be specified for this outcome']
            end
          end

          context 'exemption cost' do
            it 'is valid' do
              kase.exemptions = [ CaseClosure::Exemption.s12 ]
              expect(kase).to be_valid
            end
          end
        end
      end
    end

    context 'Info Held in part' do

      before(:each) { kase.info_held_status = CaseClosure::InfoHeldStatus.part_held }

      context 'Granted in full' do
        before(:each) { kase.outcome = CaseClosure::Outcome.granted }

        context 'no refusal reason or exemptions' do
          it 'is valid' do
            kase.refusal_reason = nil
            kase.exemptions = []
            expect(kase).to be_valid
          end
        end

        context 'refusal reason supplied' do
          it 'is not valid' do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context 'exemption supplied' do
          it 'is not valid' do
            kase.exemptions = [ CaseClosure::Exemption.s27 ]
            expect(kase).not_to be_valid
            expect(kase.errors[:exemptions]).to eq ['cannot be present unless case was fully or partly refused, or information held not confirmed and NCND']
          end
        end
      end

      context 'Refused in part' do
        before(:each)  { kase.outcome = CaseClosure::Outcome.part_refused }

        context 'refusal reason supplied' do
          it 'is not valid' do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context 'no refusal reason supplied' do
          before(:each) { kase.refusal_reason = nil }

          context 'at least one exemption supplied' do
            it 'is valid' do
              kase.exemptions = [ CaseClosure::Exemption.s27 ]
              expect(kase).to be_valid
            end
          end

          context 'multiple exemptions supplied' do
            it 'is valid' do
              kase.exemptions = [ CaseClosure::Exemption.s27, CaseClosure::Exemption.s35 ]
              expect(kase).to be_valid
            end
          end

          context 'no exemptions supplied' do
            it 'is not valid' do
              kase.exemptions = []
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ['must be specified for this outcome']
            end
          end

          context 'cost exemption is supplied' do
            it 'is invalid' do
              kase.exemptions = [ CaseClosure::Exemption.s12 ]
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ['cost is not valid for part refusals']
            end
          end
        end
      end

      context 'Refused in full' do
        before(:each)  { kase.outcome = CaseClosure::Outcome.fully_refused }

        context 'refusal reason supplied' do
          it 'is not valid' do
            kase.refusal_reason = CaseClosure::RefusalReason.vex
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
          end
        end

        context 'no refusal reason supplied' do
          before(:each) { kase.refusal_reason = nil }

          context 'at least one exemption supplied' do
            it 'is valid' do
              kase.exemptions = [ CaseClosure::Exemption.s27 ]
              expect(kase).to be_valid
            end
          end

          context 'multiple exemptions supplied' do
            it 'is valid' do
              kase.exemptions = [ CaseClosure::Exemption.s27, CaseClosure::Exemption.s35 ]
              expect(kase).to be_valid
            end
          end

          context 'no exemptions supplied' do
            it 'is not valid' do
              kase.exemptions = []
              expect(kase).not_to be_valid
              expect(kase.errors[:exemptions]).to eq ['must be specified for this outcome']
            end
          end

          context 'exemption cost' do
            it 'is valid' do
              kase.exemptions = [ CaseClosure::Exemption.s12 ]
              expect(kase).to be_valid
            end
          end
        end
      end
    end

    context 'Info not held' do
      before(:each) do
        kase.info_held_status = CaseClosure::InfoHeldStatus.not_held
        kase.refusal_reason = nil
        kase.outcome = nil
        kase.exemptions = []
      end

      context 'no refusal reason' do
        it 'is valid' do
          expect(kase).to be_valid
        end
      end

      context 'refusal reason present' do
        it 'is invalid' do
          kase.refusal_reason = CaseClosure::RefusalReason.vex
          expect(kase).not_to be_valid
          expect(kase.errors[:refusal_reason]).to eq ["cannot be present unless Information Held in 'Other'"]
        end
      end

      context 'outcome present' do
        it 'is invalid' do
          kase.outcome = CaseClosure::Outcome.first
          expect(kase).not_to be_valid
          expect(kase.errors[:outcome]).to eq ['can only be present if information held or part held']
        end
      end

      context 'exemptions present' do
        it 'is invalid' do
          kase.exemptions = [ CaseClosure::Exemption.first ]
          expect(kase).not_to be_valid
          expect(kase.errors[:exemptions]).to eq ['cannot be present unless case was fully or partly refused, or information held not confirmed and NCND']
        end
      end
    end

    context 'Info not confirmed (a.k.a Other)' do
      before(:each) do
        kase.info_held_status = CaseClosure::InfoHeldStatus.not_confirmed
        kase.outcome = nil
        kase.refusal_reason = CaseClosure::RefusalReason.first
      end

      context 'refusal reason present, exemption present, but no outcome or refusal reason' do
        it 'is invalid' do
          expect(kase).to be_valid
        end
      end

      context 'no refusal reason present' do
        it 'is not valid' do
          kase.refusal_reason = nil
          expect(kase).not_to be_valid
          expect(kase.errors[:refusal_reason]).to eq ['must be present for the specified outcome']
        end
      end

      context 'outcome present' do
        it 'is invalid' do
          kase.outcome = CaseClosure::Outcome.first
          expect(kase).not_to be_valid
          expect(kase.errors[:outcome]).to eq ['can only be present if information held or part held']
        end
      end

      context 'exemptions not present' do
        it 'is is valid' do
          kase.exemptions = []
          expect(kase).to be_valid
        end
      end

      context 'exemption present' do
        it 'is not valid' do
          kase.exemptions = [ CaseClosure::Exemption.s12 ]
          expect(kase).not_to be_valid
          expect(kase.errors[:exemptions]).to eq ['cannot be present unless case was fully or partly refused, or information held not confirmed and NCND']
        end
      end

      context 'refusal reason is NCND' do
        context 'no exemption present' do
          it 'is not valid' do
            kase.refusal_reason = CaseClosure::RefusalReason.ncnd
            expect(kase).not_to be_valid
            expect(kase.errors[:exemptions]).to eq ['must be specified for this outcome']
          end
        end

        context 'with an exemption' do
          it 'is valid' do
            kase.refusal_reason = CaseClosure::RefusalReason.ncnd
            kase.exemptions = [ CaseClosure::Exemption.first ]
            expect(kase).to be_valid
          end
        end
      end
    end
  end


  context 'ICO Appeal cases' do

    let(:responded_ico)       { build :responded_ico_foi_case }

    before(:each) do
      responded_ico.prepare_for_close
    end

    context 'ico_decision' do

      before(:each)  do
        responded_ico.update(
                         date_ico_decision_received: Date.today,
                         ico_decision: 'upheld',
                         uploaded_ico_decision_files:  %w{ file_1 file2 }
        )
      end

      context 'blank' do
        it 'is invalid' do
          responded_ico.ico_decision = nil
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:ico_decision]).to eq ['blank']
        end
      end

      context 'just right' do
        it 'is valid' do
          expect(responded_ico).to be_valid
        end
      end
    end



    context 'date_ico_decision_received' do

      before(:each)   do
        responded_ico.ico_decision = 'upheld'
        responded_ico.uploaded_ico_decision_files = %w{ file_1 file2 }
      end


      context 'blank' do
        it 'is invalid' do
          responded_ico.date_ico_decision_received = nil
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:date_ico_decision_received]).to eq ["cannot be blank"]
        end
      end
      context 'future' do
        it 'is invalid' do
          responded_ico.date_ico_decision_received = Date.tomorrow
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:date_ico_decision_received]).to eq ['future']
        end
      end

      context 'too far in the past' do
        it 'is invalid' do
          responded_ico.date_ico_decision_received = responded_ico.created_at - 1.day
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:date_ico_decision_received]).to eq ['before creation date']
        end
      end

      context 'just right' do
        context 'yesterday' do
          it 'is valid' do
            responded_ico.date_ico_decision_received = Date.yesterday
            expect(responded_ico).to be_valid
          end
        end

        context 'creation date' do
          it 'is valid' do
            responded_ico.date_ico_decision_received = responded_ico.created_at.to_date
            expect(responded_ico).to be_valid
          end
        end
      end
    end

    context 'uploaded ico decision files' do

      before(:each) do
        responded_ico.date_ico_decision_received = Date.today
        responded_ico.uploaded_ico_decision_files = nil
        responded_ico.ico_decision_comment = nil
      end

      context 'decision upheld' do
        before(:each)   do
          responded_ico.ico_decision = 'upheld'
        end

        context 'files and decision blank' do
          it 'is not valid' do
            expect(responded_ico).not_to be_valid
          end
        end

        context 'files uploaded' do
          it 'is valid' do
            responded_ico.uploaded_ico_decision_files = %w{ file_1 file2 }
            expect(responded_ico).to be_valid
          end
        end
      end

      context 'decision overturned' do
        before(:each) do
          responded_ico.ico_decision = 'overturned'
        end

        context 'uploaded ico decision files blank' do
          it 'is invalid' do
            expect(responded_ico).not_to be_valid
            expect(responded_ico.errors[:uploaded_ico_decision_files]).to eq ['No ICO decision files have been uploaded']
          end
        end

        context 'files uploaded' do
          it 'is valid' do
            responded_ico.uploaded_ico_decision_files = %w{ file_1 file2 }
            expect(responded_ico).to be_valid
          end
        end
      end
    end
  end

  context 'SAR IR cases' do

    let!(:sar_ir) { create(:ready_to_close_sar_internal_review) }
    let(:outcome_reason_ids) { CaseClosure::OutcomeReason.all.map(&:id) }

    before(:each) do
      sar_ir.prepare_for_close
    end

    context '#validate_sar_ir_outcome' do
      context 'sar_ir_outcome blank' do
        it 'has correct error' do
          sar_ir.valid?
          expect(sar_ir.errors[:sar_ir_outcome]).to eq ['must be selected']
        end
      end

      context 'sar_ir_outcome present' do
        it 'has no errors' do
          sar_ir.sar_ir_outcome = 'Upheld'
          sar_ir.valid?
          expect(sar_ir.errors[:sar_ir_outcome]).to eq [] 
        end
      end
    end

    context '#validate_outcome_reasons' do
      context 'outcome reasons blank' do
        it 'has correct error' do
          sar_ir.sar_ir_outcome = 'Upheld in part'
          sar_ir.valid?
          expect(sar_ir.errors[:outcome_reasons]).to eq ['must be selected']
        end
      end

      context 'ourcome reasonss present' do
        it 'has no errors' do
          sar_ir.sar_ir_outcome = 'Upheld in part'
          sar_ir.outcome_reason_ids = outcome_reason_ids
          sar_ir.valid?
          expect(sar_ir.errors[:outcome_reasons]).to eq [] 
        end
      end
    end

    context '#validate_team_responsible' do
      context 'team responsible blank' do
        it 'has correct error' do
          sar_ir.sar_ir_outcome = 'Upheld in part'
          sar_ir.valid?
          expect(sar_ir.errors[:team_responsible_for_outcome_id]).to eq ['must be selected']
        end
      end

      context 'team responsible present' do
        it 'has no errors' do
          sar_ir.sar_ir_outcome = 'Upheld in part'
          sar_ir.team_responsible_for_outcome_id = 1
          sar_ir.valid?
          expect(sar_ir.errors[:team_responsible_for_outcome_id]).to eq [] 
        end
      end
    end
  end
end

