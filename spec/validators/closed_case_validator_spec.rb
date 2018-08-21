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

    describe 'date responded validation' do

      before(:each) do
        kase.outcome = CaseClosure::Outcome.granted
        kase.info_held_status = CaseClosure::InfoHeldStatus.part_held
      end

      it 'errors if date_responded blank' do
        kase.date_responded = nil
        expect(kase).not_to be_valid
        expect(kase.errors[:date_responded]).to eq(["can't be blank"])
      end

      it 'errors if date_responded in the future' do
        kase.date_responded = 3.days.from_now
        expect(kase).not_to be_valid
        expect(kase.errors[:date_responded]).to eq(["can't be in the future"])
      end

      it 'errors if date before received date' do
        kase.date_responded = kase.received_date - 1.day
        expect(kase).not_to be_valid
        expect(kase.errors[:date_responded]).to eq(["can't be before date received"])
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

      context 'blank' do
        it 'is invalid' do
          responded_ico.ico_decision = nil
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:ico_decision]).to eq ['blank']
        end
      end

      context 'not a valid decision' do
        it 'is invalid' do
          responded_ico.ico_decision = 'xxx'
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:ico_decision]).to eq ['invalid']
        end
      end

      context 'just right' do
        it 'is valid' do
          responded_ico.ico_decision = 'overturned'
          expect(responded_ico).to be_valid
        end
      end
    end



    context 'date_ico_decision_received' do

      context 'blank' do
        it 'is invalid' do
          responded_ico.date_ico_decision_received = nil
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:date_ico_decision_received]).to eq ["can't be blank"]
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
          responded_ico.date_ico_decision_received = 2.months.ago
          expect(responded_ico).not_to be_valid
          expect(responded_ico.errors[:date_ico_decision_received]).to eq ['past']
        end
      end

      context 'just right' do
        it 'is valid' do
          responded_ico.date_ico_decision_received = Date.yesterday
          expect(responded_ico).to be_valid
        end
      end


    end

    context 'files and or ico decision comment' do

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
          it 'is valid' do
            expect(responded_ico).to be_valid
          end
        end

        context 'files uploaded' do
          it 'is valid' do
            responded_ico.uploaded_ico_decision_files = %w{ file_1 file2 }
            expect(responded_ico).to be_valid
          end
        end

        context 'decision comment specified' do
          it 'is valid' do
            responded_ico.ico_decision_comment = 'Rubbish!'
            expect(responded_ico).to be_valid
          end
        end

        context 'files uploaded and decision comment specified'
        it 'is valid' do
          responded_ico.ico_decision_comment = 'Rubbish!'
          responded_ico.uploaded_ico_decision_files = %w{ file_1 file2 }
          expect(responded_ico).to be_valid
        end
      end

      context 'decision overturned' do
        before(:each) do
          responded_ico.ico_decision = 'overturned'
        end

        context 'files and decision blank' do
          it 'is invalid' do
            expect(responded_ico).not_to be_valid
            expect(responded_ico.errors[:uploaded_ico_decision_files]).to eq ['blank']
          end
        end

        context 'files uploaded' do
          it 'is valid' do
            responded_ico.uploaded_ico_decision_files = %w{ file_1 file2 }
            expect(responded_ico).to be_valid
          end
        end

        context 'decision comment specified' do
          it 'is valid' do
            responded_ico.ico_decision_comment = 'Rubbish!'
            expect(responded_ico).to be_valid
          end
        end

        context 'files uploaded and decision comment specified'
        it 'is valid' do
          responded_ico.ico_decision_comment = 'Rubbish!'
          responded_ico.uploaded_ico_decision_files = %w{ file_1 file2 }
          expect(responded_ico).to be_valid
        end

      end
    end
  end

end

