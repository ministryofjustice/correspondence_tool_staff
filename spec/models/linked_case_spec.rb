require 'rails_helper'

describe LinkedCase do
  let(:foi)       { create :case }
  let(:other_foi) { create :case }
  let(:sar)       { create :sar_case }

  it 'creates reverse links automatically' do
    expect {
      LinkedCase.create(case: foi, linked_case: other_foi)
    }.to change(LinkedCase, :count).by(2)
    expect(LinkedCase.first.case_id).to eq foi.id
    expect(LinkedCase.first.linked_case_id).to eq other_foi.id
    expect(LinkedCase.first.related?).to be_truthy

    expect(LinkedCase.last.case_id).to eq other_foi.id
    expect(LinkedCase.last.linked_case_id).to eq foi.id
    expect(LinkedCase.last.related?).to be_truthy
  end

  it 'destroys reverse links automatically' do
    link = LinkedCase.create(case: foi, linked_case: other_foi)
    expect(LinkedCase.first.case_id).to eq foi.id
    expect(LinkedCase.last.case_id).to eq other_foi.id

    expect {
      link.destroy
    }.to change(LinkedCase, :count).by(-2)
    expect(LinkedCase.all).to be_empty
  end

  describe '#linked_case' do
    context 'FOI case' do
      it 'can link to a FOI case' do
        case_link = LinkedCase.create(case: foi, linked_case: other_foi)
        expect(case_link).to be_valid
      end

      it 'cannot be linked to itself' do
        case_link = LinkedCase.create(case: foi, linked_case: foi)
        expect(case_link).not_to be_valid
        expect(case_link.errors[:linked_case])
          .to eq ['cannot be linked to itself']
      end

      it 'cannot link to a SAR case' do
        case_link = LinkedCase.create(case: foi, linked_case: sar)
        expect(case_link).not_to be_valid
        expect(case_link.errors[:linked_case])
          .to eq ["case 'Case::SAR' cannot be linked to 'Case::FOI::Standard' as 'related' case"]
      end
    end
  end
end
