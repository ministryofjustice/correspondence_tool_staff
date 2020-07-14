require 'rails_helper'

RSpec.describe Letter, type: :model do
  let(:letter_template) { create(:letter_template, name: "Letter to Requester") }
  let(:kase) { create(:offender_sar_case, name: 'Waylon Smithers') }

  it 'can be created' do
    letter = Letter.new 1
    expect(letter.letter_template_id).to eq 1
  end

  it 'delegates values to a case' do
    letter = Letter.new(letter_template.id, kase)
    expect(letter.values.name).to eq "Waylon Smithers"
  end

  it 'renders a case' do
    letter = Letter.new(letter_template.id, kase)
    expect(letter.body).to eq 'Thank you for your offender subject access request, Waylon Smithers'
  end

  it 'displays the template name' do
    letter = Letter.new(letter_template.id, kase)
    expect(letter.template_name).to eq 'Letter to Requester'
  end

  describe '#letter_recipient' do
    context 'when letter template is acknowledgement letter' do
      context 'when subject is requester' do
        it  'returns the subject name' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.letter_recipient).to eq kase.requester_name
          expect(letter.letter_recipient).to eq kase.subject_name
        end
      end

      context 'when third party is requester' do
        let(:kase) { build(:offender_sar_case, :third_party, third_party_name: "Bob") }
        it  'returns the third_party name' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.letter_recipient).to eq kase.requester_name
          expect(letter.letter_recipient).to eq kase.third_party_name
        end
      end
    end

    context 'when letter template is dispatch letter' do
      let(:letter_template) { create(:letter_template, template_type: "dispatch", name: "Letter to Recipient") }

      context 'when subject is recipient' do
        it  'returns the subject name' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.letter_recipient).to eq kase.recipient_name
          expect(letter.letter_recipient).to eq kase.subject_name
        end
      end

      context 'when third party is recipient' do
        let(:kase) { build(:offender_sar_case, :third_party, third_party_name: "Bob") }

        it  'returns the third_party name' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.letter_recipient).to eq kase.recipient_name
          expect(letter.letter_recipient).to eq kase.third_party_name
        end
      end
    end
  end
end
