require 'rails_helper'

RSpec.describe Letter, type: :model do
  it 'can be created' do
    letter = Letter.new 1
    expect(letter.letter_template_id).to eq 1
  end
end
