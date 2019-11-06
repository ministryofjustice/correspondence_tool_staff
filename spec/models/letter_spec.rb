require 'rails_helper'

RSpec.describe Letter, type: :model do
  let(:letter_template) { create(:letter_template) }
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
end
