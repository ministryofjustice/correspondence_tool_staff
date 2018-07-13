require 'rails_helper'

describe LinkedCase do
  it 'creates reverse links automatically' do
    foi_1 = create :case
    foi_2 = create :case
    LinkedCase.create(case: foi_1, linked_case: foi_2)

    expect(LinkedCase.first.case_id).to eq foi_1.id
    expect(LinkedCase.first.linked_case_id).to eq foi_2.id
    expect(LinkedCase.first.related?).to be_truthy

    expect(LinkedCase.last.case_id).to eq foi_2.id
    expect(LinkedCase.last.linked_case_id).to eq foi_1.id
    expect(LinkedCase.last.related?).to be_truthy
  end
end
