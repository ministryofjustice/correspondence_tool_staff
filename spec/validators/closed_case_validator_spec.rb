require 'rails_helper'

describe 'ClosedCaseValidator' do

  context 'preparing for close validations' do

    let(:kase) { create :case }

    context 'when closed / preparing for closed' do

      before(:each) { kase.prepare_for_close }

      describe 'date responded validation' do
        it 'errors if date_responded blank' do
          expect(kase).not_to be_valid
          expect(kase.errors[:date_responded]).to eq(["can't be blank"])
        end

        it 'errors if date_responded in the future' do
          kase.date_responded = 3.days.from_now
          expect(kase).not_to be_valid
          expect(kase.errors[:date_responded]).to eq(["can't be in the future"])
        end
      end

      describe 'outcome validations' do
        it 'errors if not present' do
          expect(kase).not_to be_valid
          expect(kase.errors[:outcome]).to eq(["can't be blank"])
        end
      end

      describe 'refusal reason validations' do

        before(:all) do
          @outcome1 = create :outcome, :requires_refusal_reason
          @outcome2 = create :outcome
          @reason = create :refusal_reason
        end

        after(:all) { CaseClosure::Metadatum.delete_all }

        context 'outcome requires refusal reason' do
          it 'errors if refusal reason not present' do
            kase = build :case, outcome: @outcome1, date_responded: 3.days.ago
            kase.prepare_for_close
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to include('must be present for the specified outcome')
          end

          it 'does not error if refusal reason present' do
            kase = build :case, outcome: @outcome1, refusal_reason: @reason, date_responded: 3.days.ago
            kase.prepare_for_close
            expect(kase).to be_valid
          end
        end

        context 'outcome does not require refusal reason' do
          it 'errors if refusal reason present' do
            kase = build :case, outcome: @outcome2, refusal_reason: @reason, date_responded: 3.days.ago
            kase.prepare_for_close
            expect(kase).not_to be_valid
            expect(kase.errors[:refusal_reason]).to include('cannot be present for the specified outcome')
          end

          it 'does not error if refusal reason absent' do
            kase = build :case, outcome: @outcome2
            expect(kase).to be_valid
          end

        end
      end

      context 'exemption validations' do

        let(:ex_1) { create :exemption }
        let(:ex_2) { create :exemption }

        context 'refusal reason exemption applied' do

          let(:kase) { create :closed_case, :requires_exemption }

          it 'errors if no exemption present' do
            kase.exemptions.map(&:destroy)
            kase.reload
            expect(kase.refusal_reason.requires_exemption?).to be true
            expect(kase.exemptions).to be_empty
            expect(kase).not_to be_valid
            expect(kase.errors[:exemptions]).to include('At least one exemption must be selected for this refusal reason')
          end

          it 'does not error if at least one exemption present' do
            kase.exemptions = [ex_1, ex_2]
            expect(kase.refusal_reason.requires_exemption?).to be true
            expect(kase.exemptions).not_to be_empty
            expect(kase).to be_valid
          end
        end

        context 'refusal reason other than exemption applied' do
          it 'errors if exemptions present' do
            kase = create :closed_case, :without_exemption
            kase.exemptions = [ex_1]
            expect(kase.refusal_reason.requires_exemption?).to be false
            expect(kase.exemptions).not_to be_empty
            expect(kase).not_to be_valid
            expect(kase.errors[:exemptions]).to include('You cannot specify exemptions for this refusal reason')
          end
        end

        context 'NCND exemption present' do
          it 'errors if no other exemption present' do
            kase = create :closed_case, :with_ncnd_exemption
            kase.exemptions.last.destroy
            expect(kase.reload.exemptions.size).to eq 1
            expect(kase.exemptions.first).to be_ncnd
            expect(kase).not_to be_valid
            expect(kase.errors[:exemptions]).to include('You must specify at least one other exemption if you select NCND')
          end

          it 'does not error is another exemption present' do
            kase = create :closed_case, :with_ncnd_exemption
            kase.exemptions.last.destroy
            kase.reload.exemptions << create(:exemption)
            expect(kase.exemptions.size).to eq 2
            expect(kase.exemptions.first).to be_ncnd
            expect(kase.exemptions.last).not_to be_ncnd
            expect(kase).to be_valid
          end
        end


        context 'NCND not present' do
          it 'does not error if '
        end
      end
    end
  end
end

