require 'rails_helper'

describe 'cases/filters/index.html.slim', type: :view do
  def allow_case_policy(policy_name)
    policy = double('Pundit::Policy', policy_name => true)
    allow(view).to receive(:policy).with(:case).and_return(policy)
  end

  def disallow_case_policy(policy_name)
    policy = double('Pundit::Policy', policy_name => false)
    allow(view).to receive(:policy).with(:case).and_return(policy)
  end

  let(:responder)       { find_or_create :foi_responder }
  let(:manager)               { find_or_create :disclosure_specialist_bmt }
  let(:responding_team) { responder.responding_teams.first }
  let(:assigned_case)   { create(:assigned_case, :flagged_accepted,
                                 responding_team: responding_team)
                            .decorate }
  let(:accepted_case)   { create(:accepted_case, :flagged_accepted,
                                 responder: responder)
                            .decorate }
  
  let(:search_query) { build :search_query }
  let(:unflagged_case) { create(:case,
                                responding_team: responding_team)
                             .decorate }

  let(:ovt_foi_trigger_case)    { create(:accepted_ot_ico_foi).decorate }

  let(:branston_responder) { find_or_create :branston_user }
  let(:offender_sar_case) { create :offender_sar_case}
  let(:offender_sar_case_third_party_name) { create :offender_sar_case, 
                                                      third_party_relationship: 'family',
                                                      third_party: true, 
                                                      third_party_name: "third_party_name"}
  let(:offender_sar_case_third_party_company) { create :offender_sar_case, 
                                                        third_party_relationship: 'solicitor',
                                                        third_party: true, 
                                                        third_party_company_name: "third_party_company_name"}

  let(:request)         { instance_double ActionDispatch::Request,
                                          path: '/cases/open',
                                          fullpath: '/cases/open',
                                          query_parameters: {},
                                          params: {}}

  before do
    assign(:global_nav_manager, GlobalNavManager.new(responder,
                                                     request,
                                                     Settings.global_navigation.pages))
    allow(request).to receive(:filtered_parameters).and_return({})
    assign(:homepage_nav_manager, GlobalNavManager.new(responder,
                                                     request,
                                                     Settings.homepage_navigation.pages))
  end

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  it 'displays the cases given it' do
    login_as responder
    assigned_case
    accepted_case
    unflagged_case
    ovt_foi_trigger_case

    assign(:cases, PaginatingDecorator.new(Case::Base.all.page.order(:number)))
    assign(:state_selector, StateSelector.new( {} ))
    assign(:query, search_query)
    assign(:action_url, '/cases/open')
    assign(:current_tab_name, 'open')

    disallow_case_policy :can_add_case?

    render
    cases_page.load(rendered)

    zeroth_case = cases_page.case_list[0]
    expect(zeroth_case.number.text).to eq "Case number #{ovt_foi_trigger_case.original_case.number}"
    expect(zeroth_case.type.text).to eq "FOI "
    expect(zeroth_case.request_detail.text)
        .to eq "#{ ovt_foi_trigger_case.original_case.subject } #{ovt_foi_trigger_case.original_case.name}"
    expect(zeroth_case.draft_deadline.text).to eq ovt_foi_trigger_case.original_case.internal_deadline
    expect(zeroth_case.external_deadline.text)
        .to eq ovt_foi_trigger_case.original_case.external_deadline
    expect(zeroth_case.status.text).to eq ovt_foi_trigger_case.original_case.status
    expect(zeroth_case.who_its_with.text).to eq ""

    first_case = cases_page.case_list[1]
    expect(first_case.number.text).to eq "Case number #{ovt_foi_trigger_case.original_ico_appeal.number}"
    expect(first_case.type.text).to eq "ICO appeal (FOI) "
    expect(first_case.flag.text).to eq "This is a Trigger case"
    expect(first_case.request_detail.text)
        .to eq "#{ ovt_foi_trigger_case.original_ico_appeal.subject } #{ovt_foi_trigger_case.original_ico_appeal.name}"
    expect(first_case.draft_deadline.text).to eq ovt_foi_trigger_case.original_ico_appeal.internal_deadline
    expect(first_case.external_deadline.text)
        .to eq ovt_foi_trigger_case.original_ico_appeal.external_deadline
    expect(first_case.status.text).to eq ovt_foi_trigger_case.original_ico_appeal.status
    expect(first_case.who_its_with.text).to eq ""

    second_case = cases_page.case_list[2]
    expect(second_case.number.text).to eq "Case number #{assigned_case.number}"
    expect(second_case.type.text).to eq "FOI "
    expect(second_case.flag.text).to eq "This is a Trigger case"
    expect(second_case.request_detail.text)
      .to eq "#{ assigned_case.subject } #{assigned_case.name}"
    expect(second_case.draft_deadline.text).to eq assigned_case.internal_deadline
    expect(second_case.external_deadline.text)
      .to eq assigned_case.external_deadline
    expect(second_case.status.text).to eq assigned_case.status
    expect(second_case.who_its_with.text).to eq assigned_case.who_its_with

    third_case = cases_page.case_list[3]
    expect(third_case.number.text).to eq "Case number #{accepted_case.number}"
    expect(third_case.request_detail.text)
      .to eq "#{ accepted_case.subject } #{accepted_case.name}"
    expect(third_case.draft_deadline.text).to eq accepted_case.internal_deadline
    expect(third_case.external_deadline.text)
      .to eq accepted_case.external_deadline
    expect(third_case.status.text).to eq accepted_case.status
    expect(third_case.who_its_with.text).to eq accepted_case.who_its_with

    fourth_case = cases_page.case_list[4]
    expect(fourth_case.number.text).to eq "Case number #{ovt_foi_trigger_case.number}"
    expect(fourth_case.type.text).to eq "ICO overturned (FOI) "
    expect(fourth_case.request_detail.text)
        .to eq "#{ovt_foi_trigger_case.subject} #{ovt_foi_trigger_case.name}"
    expect(fourth_case.draft_deadline.text).to eq ovt_foi_trigger_case.internal_deadline
    expect(fourth_case.external_deadline.text)
        .to eq ovt_foi_trigger_case.external_deadline
    expect(fourth_case.status.text).to eq ovt_foi_trigger_case.status
    expect(fourth_case.who_its_with.text).to eq ovt_foi_trigger_case.who_its_with

    fifth_case = cases_page.case_list[5]
    expect(fifth_case.number.text).to eq "Case number #{unflagged_case.number}"
    expect(fifth_case.type.text).to eq "FOI "
    expect(fifth_case.request_detail.text)
      .to eq "#{unflagged_case.subject} #{unflagged_case.name}"
    expect(fifth_case.draft_deadline.text).to eq ' '
    expect(fifth_case.external_deadline.text)
      .to eq unflagged_case.external_deadline
    expect(fifth_case.status.text).to eq unflagged_case.status
    expect(fifth_case.who_its_with.text).to eq unflagged_case.who_its_with
  end

  it 'displays the offender SAR related cases given it' do
    login_as branston_responder
    offender_sar_case
    offender_sar_case_third_party_name
    offender_sar_case_third_party_company

    assign(:cases, PaginatingDecorator.new(Case::Base.all.page.order(:number)))
    assign(:state_selector, StateSelector.new( {} ))
    assign(:query, search_query)
    assign(:action_url, '/cases/open')
    assign(:current_tab_name, 'open')

    disallow_case_policy :can_add_case?

    render
    cases_page.load(rendered)

    zeroth_case = cases_page.case_list[0]
    expect(zeroth_case.number.text).to eq "Case number #{offender_sar_case.number}"
    expect(zeroth_case.type.text).to eq "Offender SAR "
    expect(zeroth_case.request_detail.text)
        .to eq "#{ offender_sar_case.subject} #{ offender_sar_case.subject}"
    expect(zeroth_case.status.text).to eq offender_sar_case.decorate.status
    expect(zeroth_case.who_its_with.text).to eq offender_sar_case.decorate.who_its_with
    expect(zeroth_case.external_deadline.text)
        .to eq offender_sar_case.decorate.external_deadline

    first_case = cases_page.case_list[1]
    expect(first_case.number.text).to eq "Case number #{offender_sar_case_third_party_name.number}"
    expect(first_case.type.text).to eq "Offender SAR "
    expect(first_case.request_detail.text)
        .to eq "#{ offender_sar_case_third_party_name.subject} #{ offender_sar_case_third_party_name.third_party_name}"
    expect(first_case.status.text).to eq offender_sar_case_third_party_name.decorate.status
    expect(first_case.who_its_with.text).to eq offender_sar_case_third_party_name.decorate.who_its_with
    expect(first_case.external_deadline.text)
        .to eq offender_sar_case_third_party_name.decorate.external_deadline

    second_case = cases_page.case_list[2]
    expect(second_case.number.text).to eq "Case number #{offender_sar_case_third_party_company.number}"
    expect(second_case.type.text).to eq "Offender SAR "
    expect(second_case.request_detail.text)
        .to eq "#{ offender_sar_case_third_party_company.subject} #{ offender_sar_case_third_party_company.third_party_company_name}"
    expect(second_case.status.text).to eq offender_sar_case_third_party_company.decorate.status
    expect(second_case.who_its_with.text).to eq offender_sar_case_third_party_company.decorate.who_its_with
    expect(second_case.external_deadline.text)
        .to eq offender_sar_case_third_party_company.decorate.external_deadline
  end

  describe 'add case button' do
    it 'is displayed when the user can add cases' do
      login_as manager
      assign(:cases, PaginatingDecorator.new(Case::Base.all.page))
      assign(:state_selector, StateSelector.new( {} ))
      assign(:query, search_query)
      assign(:action_url, '/cases/open')
      assign(:can_add_case, true)

      allow_case_policy :can_add_case?

      render
      cases_page.load(rendered)

      expect(cases_page).to have_new_case_button
    end

    it 'is not displayed when the user cannot add cases' do
      login_as manager
      assign(:cases, PaginatingDecorator.new(Case::Base.all.page))
      assign(:query, search_query)
      assign(:action_url, '/cases/open')
      assign(:state_selector, StateSelector.new( {} ))

      disallow_case_policy :can_add_case?

      render
      cases_page.load(rendered)

      expect(cases_page).not_to have_new_case_button
    end
  end

  describe 'pagination' do
    before do
      allow(view).to receive(:policy).and_return(spy('Pundit::Policy'))
    end

    it 'renders the paginator' do
      login_as manager
      assigned_case
      assign(:cases, Case::Base.none.page.decorate)
      assign(:query, search_query)
      assign(:action_url, '/cases/open')
      assign(:state_selector, StateSelector.new( {} ))
      render
      expect(response).to have_rendered('cases/filters/index')
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

      it 'has no link to the prev page' do
        expect(@partial).to have_no_prev_page_link
      end

      it 'has no link to the next page' do
        expect(@partial).to have_no_next_page_link
      end
    end

  end
end
