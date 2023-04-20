require 'rails_helper'

describe 'cases/sar/new.html.slim', type: :view do
  let(:sar_case)                { build_stubbed :sar_case }
  let(:disclosure_specialist)   { find_or_create :disclosure_specialist }

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  before(:each) { login_as disclosure_specialist }

  xdescribe 'sar form' do
    it 'asks for data subjects info' do
      render partial: 'cases/sar/new_form_common',
             locals:{ kase: sar_case}

    end

    # expect()
  end



  # describe 'basic_details' do
  #   it 'displays the initial case details' do
  #     render partial: 'cases/case_details',
  #            locals:{ case_details: unassigned_case}
  #
  #     partial = case_details_section(rendered).basic_details
  #
  #     expect(partial).to be_all_there
  #
  #     expect(partial.case_type).to have_no_foi_trigger
  #
  #     expect(partial.case_type.data.text).to eq "FOI  "
  #
  #     expect(partial.date_received.data.text)
  #         .to eq unassigned_case.received_date.strftime(Settings.default_date_format)
  #
  #     expect(partial.name.data.text)
  #         .to eq unassigned_case.name
  #
  #     expect(partial.email.data.text)
  #         .to eq unassigned_case.email
  #
  #     expect(partial.address.data.text)
  #         .to eq unassigned_case.postal_address
  #
  #     expect(partial.requester_type.data.text)
  #         .to eq unassigned_case.requester_type.humanize
  #
  #     expect(partial.delivery_method.data.text)
  #         .to eq unassigned_case.delivery_method.humanize
  #
  #   end
  #
  #   it 'displays a trigger badge if the case has been triggered' do
  #     trigger_case
  #
  #     render partial: 'cases/case_details',
  #            locals:{ case_details: trigger_case}
  #
  #     partial = case_details_section(rendered).basic_details
  #
  #     expect(partial).to be_all_there
  #
  #     expect(partial.case_type).to have_foi_trigger
  #
  #     expect(partial.case_type.data.text).to eq "FOI This is a Trigger case"
  #   end
  #
  #   it 'does not display the email address if one is not provided' do
  #     unassigned_case.email = nil
  #
  #     render partial: 'cases/case_details',
  #            locals:{ case_details: unassigned_case}
  #
  #     partial = case_details_section(rendered).basic_details
  #
  #     expect(partial).to have_no_email
  #     expect(partial).to have_address
  #   end
  #
  #   it 'does not display the postal address if one is not provided' do
  #     unassigned_case.postal_address = nil
  #
  #     render partial: 'cases/case_details',
  #            locals:{ case_details: unassigned_case}
  #
  #     partial = case_details_section(rendered).basic_details
  #
  #     expect(partial).to have_no_address
  #     expect(partial).to have_email
  #   end
  # end
  # describe 'responders details' do
  #   it 'displays the responders team name' do
  #     render partial: 'cases/case_details',
  #            locals:{ case_details: accepted_case}
  #
  #     partial = case_details_section(rendered).responders_details
  #
  #     expect(partial).to be_all_there
  #     expect(partial.team.data.text).to eq accepted_case.responding_team.name
  #     expect(partial.name.data.text).to eq accepted_case.responder.full_name
  #   end
  # end
  #
  # describe 'Final response details' do
  #
  #   it 'displays all the case closure details' do
  #     closed_case
  #     render partial: 'cases/case_details',
  #            locals:{ case_details: closed_case}
  #
  #     partial = case_details_section(rendered).response_details
  #     expect(partial.date_responded.data.text).to eq closed_case.date_sent_to_requester
  #     expect(partial.timeliness.data.text).to eq closed_case.timeliness
  #     expect(partial.time_taken.data.text).to eq closed_case.time_taken
  #     expect(partial.outcome.data.text).to eq closed_case.outcome.name
  #   end
  #
  # end


end
