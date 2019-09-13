require 'rails_helper'

RSpec.describe LetterTemplate, type: :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:body) }
  it { should validate_presence_of(:template_type) }

  it { should have_enum(:template_type).
          with_values(['acknowledgement', 'dispatch']) }


  describe 'render' do
    let(:letter_template) { create(:letter_template) }
    it 'renders a template' do
      values = OpenStruct.new(name: "Bob")
      expect(letter_template.render(values))
        .to match "Thank you for your offender subject access request, Bob"
    end
  end
end
