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
                                          path: '/cases/open/in_time',
                                          fullpath: '/cases/open/in_time',
                                          query_parameters: {},
                                          params: {}}

  let(:unflagged_case) { create(:case,
                                responding_team: responding_team)
                             .decorate }

  before do
    allow(request).to receive(:filtered_parameters).and_return({})
    assign(:global_nav_manager, GlobalNavManager.new(responder,
                                                     request,
                                                     Settings.global_navigation))
  end

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  it 'displays the cases given it' do
    login_as responder
    assigned_case
    accepted_case
    unflagged_case

    assign(:cases, PaginatingDecorator.new(Case::Base.all.page.order(:number)))
    assign(:state_selector, StateSelector.new( {} ))

    disallow_case_policy :can_add_case?

    render
    cases_page.load(rendered)

    first_case = cases_page.case_list[0]
    expect(first_case.number.text).to eq "Link to case #{assigned_case.number}"
    expect(first_case.type.text).to eq "FOI This is a Trigger case"
    expect(first_case.request_detail.text)
      .to eq "#{ assigned_case.subject } #{assigned_case.name}"
    expect(first_case.draft_deadline.text).to eq assigned_case.internal_deadline
    expect(first_case.external_deadline.text)
      .to eq assigned_case.external_deadline
    expect(first_case.status.text).to eq assigned_case.status
    expect(first_case.who_its_with.text).to eq assigned_case.who_its_with

    second_case = cases_page.case_list[1]
    expect(second_case.number.text).to eq "Link to case #{accepted_case.number}"
    expect(second_case.request_detail.text)
      .to eq "#{ accepted_case.subject } #{accepted_case.name}"
    expect(second_case.draft_deadline.text).to eq accepted_case.internal_deadline
    expect(second_case.external_deadline.text)
      .to eq accepted_case.external_deadline
    expect(second_case.status.text).to eq accepted_case.status
    expect(second_case.who_its_with.text).to eq accepted_case.who_its_with

    third_case = cases_page.case_list[2]
    expect(third_case.number.text).to eq "Link to case #{unflagged_case.number}"
    expect(third_case.type.text).to eq "FOI  "
    expect(third_case.request_detail.text)
      .to eq "#{unflagged_case.subject} #{unflagged_case.name}"
    expect(third_case.draft_deadline.text).to eq ' '
    expect(third_case.external_deadline.text)
      .to eq unflagged_case.external_deadline
    expect(third_case.status.text).to eq unflagged_case.status
    expect(third_case.who_its_with.text).to eq unflagged_case.who_its_with
  end

  describe 'add case button' do
    it 'is displayed when the user can add cases' do
      assign(:cases, PaginatingDecorator.new(Case::Base.all.page))
      assign(:state_selector, StateSelector.new( {} ))
      assign(:can_add_case, true)

      allow_case_policy :can_add_case?

      render
      cases_page.load(rendered)

      expect(cases_page).to have_new_case_button
    end

    it 'is not displayed when the user cannot add cases' do
      assign(:cases, PaginatingDecorator.new(Case::Base.all.page))
      assign(:state_selector, StateSelector.new( {} ))

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
      assign(:cases, PaginatingDecorator.new(Case::Base.all.page))
      assign(:state_selector, StateSelector.new( {} ))
      render
      cases_page.load(rendered)

      expect(cases_page.tabs[0].tab_link).to have_text 'In time (0)'
      expect(cases_page.tabs[0].tab_link[:href])
        .to eq '/cases/open/in_time'
    end

    it 'has a count of how many in-time open cases there are' do
      login_as(responder)
      assigned_case
      assign(:cases, PaginatingDecorator.new(Case::Base.all.page))
      assign(:state_selector, StateSelector.new( {} ))
      render
      cases_page.load(rendered)

      expect(cases_page.tabs[0].tab_link).to have_text 'In time (1)'
    end
  end

  describe 'pagination' do
    before do
      allow(view).to receive(:policy).and_return(spy('Pundit::Policy'))
    end

    it 'renders the paginator' do
      assign(:cases, Case::Base.none.page.decorate)
      assign(:state_selector, StateSelector.new( {} ))
      render
      expect(response).to have_rendered('kaminari/_paginator')
    end

    # The following tests should ideally be in a separate spec in
    # kaminari/_paginator_html_slim_spec.rb, however when we do that, the test
    # framework tries to create links for a controller called 'kaminari'. Until
    # we have a way to override that, we test here and test that other views
    # include pagination.
    context 'one pages worth of cases' do
      before :all do
        create_list(:case, 20)
        @cases = Case::Base.all.page.decorate
      end
      after(:all) { DbHousekeeping.clean }

      before do
        assign(:cases, @cases)
        @partial = pagination_section(view.paginate @cases)
      end

      it 'has no pagination section' do
        expect(@partial.html).to be_blank
      end
    end

    context 'on page one of two of cases' do
      before :all do
        create_list(:case, 21)
        @cases = Case::Base.all.page(1).decorate
      end
      after(:all) { DbHousekeeping.clean }

      before do
        assign(:cases, @cases)
        @partial = pagination_section(view.paginate @cases)
      end

      it 'has no link to the prev page' do
        expect(@partial).not_to have_prev_page_link
      end

      it 'has a link to the next page' do
        expect(@partial).to have_next_page_link
      end

      it 'tells us what page is next' do
        expect(@partial.next_page_link.text).to include '2 of 2'
      end
    end

    context 'on page two of two of cases' do
      before :all do
        create_list(:case, 21)
        @cases = Case::Base.all.page(2).decorate
      end
      after(:all) { DbHousekeeping.clean }

      before do
        assign(:cases, @cases)
        @partial = pagination_section(view.paginate @cases)
      end

      it 'has a link to the prev page' do
        expect(@partial).to have_prev_page_link
      end

      it 'has no link to the next page' do
        expect(@partial).not_to have_next_page_link
      end

      it 'tells us what page is previous' do
        expect(@partial.prev_page_link.text).to include '1 of 2'
      end
    end

    context 'on page two of three of cases' do
      before :all do
        create_list(:case, 41)
        @cases = Case::Base.all.page(2).decorate
      end
      after(:all) { DbHousekeeping.clean }

      before do
        assign(:cases, @cases)
        @partial = pagination_section(view.paginate @cases)
      end

      it 'has a link to the prev page' do
        expect(@partial).to have_prev_page_link
      end

      it 'tells us what page is previous' do
        expect(@partial.prev_page_link.text).to include '1 of 3'
      end

      it 'has a link to the next page' do
        expect(@partial).to have_next_page_link
      end

      it 'tells us what page is next' do
        expect(@partial.next_page_link.text).to include '3 of 3'
      end
    end
  end
end
