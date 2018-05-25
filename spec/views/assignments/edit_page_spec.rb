require 'rails_helper'

describe 'assignments/edit.html.slim', type: :view do

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  def allow_case_policies(*policy_names)
    @policy ||= double 'Pundit::Policy'
    policy_names.each do |policy_name|
      allow(@policy).to receive(policy_name).and_return(true)
    end
    allow(view).to receive(:policy).with(awaiting_responder_case).and_return(@policy)
  end

  def disallow_case_policies(*policy_names)
    @policy ||= double 'Pundit::Policy'
    policy_names.each do |policy_name|
      allow(@policy).to receive(policy_name).and_return(false)
    end
    allow(view).to receive(:policy).with(awaiting_responder_case).and_return(@policy)
  end

  let(:responder)       { create :responder }
  let(:responding_team) { responder.responding_teams.first }
  let(:awaiting_responder_case) { create(:awaiting_responder_case, :with_messages,
                                         responding_team: responding_team).decorate }
  let(:assignment)      { awaiting_responder_case.responder_assignment }

  it 'displays the edit assignment page' do

    assign(:case, awaiting_responder_case)
    assign(:case_transitions, awaiting_responder_case.transitions.decorate)
    assign(:assignment, assignment)

    login_as responder
    allow_case_policies :can_add_message_to_case?, :request_further_clearance?, :destroy_case_link?
    disallow_case_policies :new_case_link?

    render

    assignments_edit_page.load(rendered)

    page = assignments_edit_page

    expect(page.page_heading.heading.text).to eq awaiting_responder_case.subject
    expect(page.page_heading.sub_heading.text)
        .to eq "You are viewing case number #{awaiting_responder_case.number} "

    expect(page).to have_case_status

    expect(page).to have_case_details

    expect(page).to have_request

    expect(page.message.text).to eq awaiting_responder_case.message

    expect(page).to have_messages

    expect(page).to have_new_message

    expect(page).to have_case_history

    expect(page).to have_accept_radio
    expect(page).to have_reject_radio

    expect(page.confirm_button.value).to eq "Confirm"

  end

end
