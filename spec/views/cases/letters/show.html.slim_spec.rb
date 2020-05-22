require 'rails_helper'

describe 'cases/letters/show.html.slim', type: :view do
  let(:offender_sar_case) {
    (create :offender_sar_case, subject_aliases: 'John Smith',
            date_of_birth: '2019-09-01').decorate
  }
  let!(:letter_template_acknowledgement) { create(:letter_template, :acknowledgement) }

  let(:branston_user)             { find_or_create :branston_user }

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  before(:each) { login_as branston_user }

  describe 'basic_details' do
    it 'displays the initial case details (non third party case)' do
      assign(:case, offender_sar_case)
      assign(:letter, Letter.new(letter_template_acknowledgement.id, offender_sar_case))
      assign(:type, "acknowledgement")
      render

      cases_show_letter_page.load(rendered)
      expect(cases_show_letter_page.page_heading.heading.text).to eq 'Download letter to requester 1'
    end
  end
end
