require 'rails_helper'

RSpec.describe Cases::LettersController, type: :controller do
  let(:manager) { find_or_create :disclosure_bmt_user }
  let(:offender_sar_case) { create(:offender_sar_case) }
  let(:letter_template) { create(:letter_template) }

  before do
    sign_in manager
  end

  describe "GET #new" do
    before do
      get :new, params: { case_id: offender_sar_case.id, type: "acknowledgement" }
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it 'sets @case' do
      expect(assigns(:case)).to eq offender_sar_case
    end

    it 'sets @letter_templates' do
      expect(assigns(:letter_templates)).to eq [letter_template]
    end
  end

  describe "GET #render_letter" do
    before do
      get :render_letter, params: { case_id: offender_sar_case.id, type: "acknowledgement", letter_template_id: letter_template.id }
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it 'sets @case' do
      expect(assigns(:case)).to eq offender_sar_case
    end

    it 'sets @letter_template' do
      expect(assigns(:letter_template)).to eq letter_template
    end
  end

end
