require 'rails_helper'

module Builders
  describe SteppedCaseBuilder do
    let(:user)      { find_or_create(:sar_responder) }

    let(:sar_case) { create(:sar_case) }
   
    let(:case_type) { Case::SAR::InternalReview }

    let(:params) do
      ActionController::Parameters.new(
        {
          "email"=>"asd@asd.com",
          "flag_for_disclosure_specialists"=>"yes",
          "message"=>"This is refreshed",
          "name"=>"Tom Jones",
          "postal_address"=>"",
          "received_date_dd"=>"14",
          "received_date_mm"=>"12",
          "received_date_yyyy"=>"2021",
          "sar_ir_subtype"=>"timeliness",
          "subject"=>"IR of 211208003 - Thing",
          "subject_type"=>"offender",
          "third_party"=>"true",
          "third_party_relationship"=>"Barrister",
          "reply_method"=>"send_by_email",
          "step"=>"link-sar-case"
        })
    end

    let(:session) do 
      ActiveSupport::HashWithIndifferentAccess.new(
        { 
          "sar_internal_review_state" => {
            "flag_for_disclosure_specialists"=>"yes",
            "original_case_number"=>"#{sar_case.number}",
            "original_case_id"=> sar_case.id,
            "delivery_method"=>nil,
            "email"=>"asd@asd.com",
            "name"=>"Tom Jones",
            "postal_address"=>"",
            "requester_type"=>nil,
            "subject"=>"Thing",
            "subject_full_name"=>"Dave Smith",
            "subject_type"=>"offender",
            "third_party"=>true,
            "third_party_relationship"=>"Barrister",
            "reply_method"=>"send_by_email"
          }
       })
    end

    let(:builder) do 
      SteppedCaseBuilder.new(
        case_type: case_type,
        session: session,
        params: params,
        creator: user
      )
    end

    before do
      builder.build_from_session
    end

    it 'can build a stepped case from a session' do
      expect(builder.kase).to be_a(case_type)
    end

    it 'can set the creator and the step of the case' do
      builder.set_creator_from_user

      expect(builder.kase.creator).to match(user)
    end

    it 'can set the current step' do
      builder.set_current_step

      expect(builder.kase.current_step).to match('link-sar-case')
    end

    it 'can set initial step for the case' do
      builder.set_initial_step

      expect(builder.kase.current_step).to match('link-sar-case')
    end
  end
end
