require 'rails_helper'

RSpec.describe Letter, type: :model do
  let(:letter_template) { create(:letter_template, name: "Letter to Requester") }
  let(:kase) { create(:offender_sar_case, name: 'Waylon Smithers', subject_address: 'address') }

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

  it 'renders a letter_address' do
    letter = Letter.new(letter_template.id, kase)
    expect(letter.letter_address).to eq 'Testing address'
  end

  it 'displays the template name' do
    letter = Letter.new(letter_template.id, kase)
    expect(letter.template_name).to eq 'Letter to Requester'
  end

  describe '#name' do
    context 'when letter template is acknowledgement letter' do
      context 'when subject is requester' do
        it 'returns the subject name' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.name).to eq kase.requester_name
          expect(letter.name).to eq kase.subject_name
        end
      end

      context 'when third party is requester' do
        let(:kase) { build_stubbed(:offender_sar_case, :third_party, third_party_name: "Bob") }
        it 'returns the third_party name' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.name).to eq kase.requester_name
          expect(letter.name).to eq kase.third_party_name
        end
      end
    end

    context 'when letter template is dispatch letter' do
      let(:letter_template) { create(:letter_template, template_type: "dispatch", name: "Letter to Recipient") }

      context 'when subject is recipient' do
        it 'returns the subject name' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.name).to eq kase.recipient_name
          expect(letter.name).to eq kase.subject_name
        end
      end

      context 'when third party is recipient' do
        let(:kase) { build_stubbed(:offender_sar_case, :third_party, third_party_name: "Bob") }

        it 'returns the third_party name' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.name).to eq kase.recipient_name
          expect(letter.name).to eq kase.third_party_name
        end
      end
    end
  end

  describe '#address' do
    context 'when letter template is acknowledgement letter' do
      context 'when subject is requester' do
        it 'returns the subject address' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.address).to eq kase.requester_address
          expect(letter.address).to eq kase.subject_address
        end
      end

      context 'when third party is requester' do
        let(:kase) { build_stubbed(:offender_sar_case, :third_party, postal_address: "33 High Street") }
        it 'returns the third_party address' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.address).to eq kase.requester_address
          expect(letter.address).to eq kase.third_party_address
        end
      end
    end

    context 'when letter template is dispatch letter' do
      let(:letter_template) { create(:letter_template, template_type: "dispatch", name: "Letter to Recipient") }

      context 'when subject is recipient' do
        it 'returns the subject address' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.address).to eq kase.recipient_address
          expect(letter.address).to eq kase.subject_address
        end
      end

      context 'when third party is recipient' do
        let(:kase) { build_stubbed(:offender_sar_case, :third_party, postal_address: "33 High Street") }

        it 'returns the third_party address' do
          letter = Letter.new(letter_template.id, kase)
          expect(letter.address).to eq kase.recipient_address
          expect(letter.address).to eq kase.third_party_address
        end
      end
    end
  end

  describe '#company_name' do
    context 'when no company_name is present' do
     let(:kase) { build_stubbed(:offender_sar_case) }
      it 'returns nil' do
        letter = Letter.new(letter_template.id, kase)
        expect(letter.company_name).to be_nil
      end
    end

    context 'when company_name is blank' do
     let(:kase) { build_stubbed(:offender_sar_case, :third_party, third_party_company_name: '') }
      it 'returns nil' do
        letter = Letter.new(letter_template.id, kase)
        expect(letter.company_name).to be_nil
      end
    end

    context 'when company_name is present' do
     let(:kase) { build_stubbed(:offender_sar_case, :third_party, third_party_company_name: 'Wibble') }
      it 'returns the company name' do
        letter = Letter.new(letter_template.id, kase)
        expect(letter.company_name).to eq "Wibble"
      end
    end
  end

  describe '#format_address' do
    let(:kase_two) { create(:offender_sar_case, name: 'Waylon Smithers',
                        subject_address: '22 Sample Address, Test Lane, Testingington, TE57ST') }

    it 'formats address into new lines' do
      letter = Letter.new(letter_template.id, kase_two)
      address_with_newlines = letter.address
      expect(address_with_newlines).to eq "22 Sample Address\nTest Lane\nTestingington\nTE57ST"
    end
  end
end
