require 'rails_helper'

describe 'cases/_what_do_you_want_to_do.html.slim', type: :view do
  let(:approver)      { create :approver }
  let(:assigned_case) { create :assigned_case, :flagged }
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
