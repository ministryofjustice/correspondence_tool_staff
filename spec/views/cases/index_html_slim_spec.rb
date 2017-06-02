require 'rails_helper'

def allow_case_policy(policy_name)
  policy = double('Pundit::Policy', policy_name => true)
  allow(view).to receive(:policy).with(:case).and_return(policy)
end

def disallow_case_policy(policy_name)
  policy = double('Pundit::Policy', policy_name => false)
  allow(view).to receive(:policy).with(:case).and_return(policy)
end

describe 'cases/index.html.slim', type: :view do
  let(:responder)       { create :responder }
  let(:responding_team) { responder.responding_teams.first }
  let(:assigned_case)   { create(:assigned_case, :flagged_accepted,
                                 responding_team: responding_team)
                            .decorate }
  let(:accepted_case)   { create(:accepted_case, :flagged_accepted,
                                 responder: responder)
                            .decorate }
  let(:request)         { instance_double ActionDispatch::Request,
                                          path: '/cases/open',
                                          fullpath: '/cases/open' }

  let(:awaiting_responder_case) { create(:awaiting_responder_case,
                                         responding_team: responding_team)
                                    .decorate }

  before do
    assign(:global_nav_manager, GlobalNavManager.new(responder, request))
  end

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  it 'displays the cases given it' do
    login_as responder
    assigned_case
    accepted_case
    assign(:cases, PaginatingDecorator.new(Case.all.page))

    disallow_case_policy :can_add_case?

    render
    cases_page.load(rendered)

    first_case = cases_page.case_list[0]
    expect(first_case.number.text).to eq "Link to case #{assigned_case.number}"
    expect(first_case.request_detail.text)
      .to eq assigned_case.subject + assigned_case.name
    expect(first_case.draft_deadline.text).to eq assigned_case.internal_deadline
    expect(first_case.external_deadline.text)
      .to eq assigned_case.external_deadline
    expect(first_case.status.text).to eq assigned_case.status
    expect(first_case.who_its_with.text).to eq assigned_case.who_its_with

    second_case = cases_page.case_list[1]
    expect(second_case.number.text).to eq "Link to case #{accepted_case.number}"
    expect(second_case.request_detail.text)
      .to eq accepted_case.subject + accepted_case.name
    expect(second_case.draft_deadline.text).to eq accepted_case.internal_deadline
    expect(second_case.external_deadline.text)
      .to eq accepted_case.external_deadline
    expect(second_case.status.text).to eq accepted_case.status
    expect(second_case.who_its_with.text).to eq accepted_case.who_its_with
  end

  describe 'add case button' do
    it 'is displayed when the user can add cases' do
      assign(:cases, PaginatingDecorator.new(Case.all.page))

      allow_case_policy :can_add_case?

      render
      cases_page.load(rendered)

      expect(cases_page).to have_new_case_button
    end

    it 'is not displayed when the user cannot add cases' do
      assign(:cases, PaginatingDecorator.new(Case.all.page))

      disallow_case_policy :can_add_case?

      render
      cases_page.load(rendered)

      expect(cases_page).not_to have_new_case_button
    end
  end

  describe 'in_time tab' do
    before do
      allow(view).to receive(:policy).and_return(spy('Pundit::Policy'))
    end

    it 'has a link to in-time open cases' do
      assign(:cases, PaginatingDecorator.new(Case.all.page))
      render
      cases_page.load(rendered)

      expect(cases_page.tabs[0].tab_link).to have_text 'In time (0)'
      expect(cases_page.tabs[0].tab_link[:href])
        .to eq '/cases/open?timeliness=in_time'
    end

    it 'has a count of how many in-time open cases there are' do
      assigned_case
      assign(:cases, PaginatingDecorator.new(Case.all.page))
      render
      cases_page.load(rendered)

      expect(cases_page.tabs[0].tab_link).to have_text 'In time (1)'
    end
  end
end
