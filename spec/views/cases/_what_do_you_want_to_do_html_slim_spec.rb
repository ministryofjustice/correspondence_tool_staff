require 'rails_helper'

describe 'cases/_what_do_you_want_to_do.html.slim', type: :view do
  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  let(:dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:approver)        { create :approver,
                                 approving_team: dacu_disclosure }
  let(:assigned_case)   { create :assigned_case, :flagged_accepted,
                                 approver: approver }
  let(:partial) do
    render partial: 'cases/what_do_you_want_to_do',
           locals: { case_details: assigned_case }
    cases_what_do_you_want_to_do_section(rendered)
  end

  before do
    login_as approver
  end

  it 'has a link to take the case on' do
    expect(partial).to have_take_case_on_link
  end

  it 'has a link to de-escalate the case' do
    expect(partial).to have_de_escalate_link
  end
end
