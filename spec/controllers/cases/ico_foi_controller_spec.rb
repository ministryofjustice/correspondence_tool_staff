require "rails_helper"

RSpec.describe Cases::IcoFoiController, type: :controller do
  describe "#new" do
    let(:case_types) { %w[Case::ICO::FOI Case::ICO::SAR] }

    let(:params) { { correspondence_type: "ico" } }

    include_examples "new case spec", Case::ICO::FOI
  end

  describe "#create" do
    before do
      sign_in manager
      find_or_create :team_dacu
      find_or_create :team_dacu_disclosure
    end

    let(:manager) { create :manager }
    let(:foi_case_for_ico) { create :closed_case }
    let(:ico_received_date) { 0.business_days.ago }
    let(:ico_external_deadline) { 20.business_days.after(ico_received_date) }
    let(:ico_internal_deadline) { 10.business_days.before(ico_external_deadline) }
    let(:ico_params) do
      {
        correspondence_type: "ico",
        ico: {
          original_case_id: foi_case_for_ico.id,
          ico_officer_name: "Ian C. Oldman",
          ico_reference_number: "ICOREF1",
          message: "ICO appeal for an FOI message",
          received_date_dd: ico_received_date.day.to_s,
          received_date_mm: ico_received_date.month.to_s,
          received_date_yyyy: ico_received_date.year.to_s,
          internal_deadline_dd: ico_internal_deadline.day.to_s,
          internal_deadline_mm: ico_internal_deadline.month.to_s,
          internal_deadline_yyyy: ico_internal_deadline.year.to_s,
          external_deadline_dd: ico_external_deadline.day.to_s,
          external_deadline_mm: ico_external_deadline.month.to_s,
          external_deadline_yyyy: ico_external_deadline.year.to_s,
          uploaded_request_files: ["uploads/71/request/request.pdf"],
        },
      }
    end
    let(:deadline)          { 1.month.ago }
    let(:internal_deadline) { 20.business_days.before(deadline) }

    let(:created_case) { Case::ICO::FOI.last }

    it "makes a DB entry" do
      expect { post :create, params: ico_params }
        .to change(Case::ICO::FOI, :count).by 1
    end

    it "uses the params provided" do
      post :create, params: ico_params

      created_case = Case::ICO::FOI.last
      expect(created_case.type).to eq "Case::ICO::FOI"
      expect(created_case.ico_reference_number).to eq "ICOREF1"
      expect(created_case.ico_officer_name).to eq "Ian C. Oldman"
      expect(created_case.subject).to eq foi_case_for_ico.subject
      expect(created_case.message).to eq "ICO appeal for an FOI message"
      expect(created_case.received_date).to eq ico_received_date.to_date
      expect(created_case.internal_deadline).to eq ico_internal_deadline.to_date
      expect(created_case.external_deadline).to eq ico_external_deadline.to_date
    end

    it "displays a flash message" do
      post :create, params: ico_params
      expect(flash[:notice]).to eq "ICO appeal (FOI) case created<br/>Case number: #{created_case.number}"
    end

    context "original case not linked" do
      let(:invalid_ico_params) do
        ico_params.tap do |p|
          p[:ico].delete(:original_case_id)
        end
      end

      it "re-renders new page" do
        post :create, params: invalid_ico_params

        expect(response).to have_rendered(:new)
        expect(assigns(:case_types)).to eq [
          "Case::ICO::FOI",
          "Case::ICO::SAR",
        ]
        expect(assigns(:case)).to be_an_instance_of(Case::ICO::FOI)
        expect(assigns(:s3_direct_post)).to be_present
      end
    end
  end
end
