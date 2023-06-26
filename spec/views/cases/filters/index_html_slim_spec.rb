require "rails_helper"

describe "cases/filters/index.html.slim", type: :view do
  let(:responder)               { find_or_create :foi_responder }
  let(:manager)                 { find_or_create :disclosure_specialist_bmt }
  let(:responding_team)         { responder.responding_teams.first }
  let(:assigned_case)           do
    create(:assigned_case, :flagged_accepted,
           responding_team:)
                                    .decorate
  end
  let(:accepted_case) do
    create(:accepted_case, :flagged_accepted,
           responder:)
                                    .decorate
  end

  let(:search_query)            { build_stubbed :search_query }
  let(:unflagged_case)          do
    create(:case,
           responding_team:)
                                    .decorate
  end

  let(:ovt_foi_trigger_case)    { create(:accepted_ot_ico_foi).decorate }

  let(:branston_responder)      { find_or_create :branston_user }
  let(:offender_sar_case)       { create :offender_sar_case }
  let(:offender_sar_case_third_party_name) do
    create :offender_sar_case,
           third_party_relationship: "family",
           third_party: true,
           third_party_name: "third_party_name"
  end
  let(:offender_sar_case_third_party_company) do
    create :offender_sar_case,
           third_party_relationship: "solicitor",
           third_party: true,
           third_party_company_name: "third_party_company_name"
  end

  let(:request) do
    instance_double ActionDispatch::Request,
                    path: "/cases/open",
                    fullpath: "/cases/open",
                    query_parameters: {},
                    params: {}
  end

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

  it "displays the cases given it" do
    login_as responder
    assigned_case
    accepted_case
    unflagged_case
    ovt_foi_trigger_case
    init_setting
    render
    cases_page.load(rendered)

    validate_cases_common_fields_displayed(cases_page.case_list[0], ovt_foi_trigger_case.original_case, who_its_with: "")
    validate_cases_common_fields_displayed(cases_page.case_list[1], ovt_foi_trigger_case.original_ico_appeal, who_its_with: "")
    expect(cases_page.case_list[1].flag.text).to eq "This is a Trigger case"

    validate_cases_common_fields_displayed(cases_page.case_list[2], assigned_case)
    expect(cases_page.case_list[2].flag.text).to eq "This is a Trigger case"

    validate_cases_common_fields_displayed(cases_page.case_list[3], accepted_case)
    validate_cases_common_fields_displayed(cases_page.case_list[4], ovt_foi_trigger_case)
    validate_cases_common_fields_displayed(cases_page.case_list[5], unflagged_case)
  end

  it "displays the offender SAR related cases given it" do
    login_as branston_responder
    offender_sar_case
    offender_sar_case_third_party_name
    offender_sar_case_third_party_company
    init_setting
    render
    cases_page.load(rendered)

    validate_offender_sar_related_cases_fields_displayed(
      cases_page.case_list[0],
      offender_sar_case,
      offender_sar_case.subject,
    )

    validate_offender_sar_related_cases_fields_displayed(
      cases_page.case_list[1],
      offender_sar_case_third_party_name,
      offender_sar_case_third_party_name.third_party_name,
    )

    validate_offender_sar_related_cases_fields_displayed(
      cases_page.case_list[2],
      offender_sar_case_third_party_company,
      offender_sar_case_third_party_company.third_party_company_name,
    )
  end

  describe "add case button" do
    it "is displayed when the user can add cases" do
      login_as manager
      assign(:cases, PaginatingDecorator.new(Case::Base.all.page))
      assign(:state_selector, StateSelector.new({}))
      assign(:query, search_query)
      assign(:action_url, "/cases/open")
      assign(:can_add_case, true)

      allow_case_policies_in_view :case, :can_add_case?

      render
      cases_page.load(rendered)

      expect(cases_page).to have_new_case_button
    end

    it "is not displayed when the user cannot add cases" do
      login_as manager
      assign(:cases, PaginatingDecorator.new(Case::Base.all.page))
      assign(:query, search_query)
      assign(:action_url, "/cases/open")
      assign(:state_selector, StateSelector.new({}))

      disallow_case_policies_in_view :case, :can_add_case?

      render
      cases_page.load(rendered)

      expect(cases_page).not_to have_new_case_button
    end
  end

  describe "pagination" do
    it "renders the paginator" do
      login_as manager
      assigned_case
      assign(:cases, Case::Base.none.page.decorate)
      assign(:query, search_query)
      assign(:action_url, "/cases/open")
      assign(:state_selector, StateSelector.new({}))
      render
      expect(response).to have_rendered("cases/filters/index")
    end

    # The following tests should ideally be in a separate spec in
    # kaminari/_paginator_html_slim_spec.rb, however when we do that, the test
    # framework tries to create links for a controller called 'kaminari'. Until
    # we have a way to override that, we test here and test that other views
    # include pagination.
    context "with one pages worth of cases" do
      let(:cases) { Case::Base.all.page.decorate }
      let(:partial) { pagination_section(view.paginate(cases)) }

      before do
        create_list(:case, 20)
        assign(:cases, cases)
      end

      it "has no link to the prev page" do
        expect(partial).to have_no_prev_page_link
      end

      it "has no link to the next page" do
        expect(partial).to have_no_next_page_link
      end
    end
  end

private

  def init_setting
    assign(:cases, PaginatingDecorator.new(Case::Base.all.page.order(:number)))
    assign(:state_selector, StateSelector.new({}))
    assign(:query, search_query)
    assign(:action_url, "/cases/open")
    assign(:current_tab_name, "open")

    disallow_case_policies_in_view :case, :can_add_case?
  end

  def validate_cases_common_fields_displayed(displayed_case, compared_case, who_its_with: nil)
    expect(displayed_case.number.text).to eq "Case number #{compared_case.number}"
    expect(displayed_case.type.text).to eq "#{compared_case.decorate.pretty_type} "
    expect(displayed_case.request_detail.text)
        .to eq "#{compared_case.subject} #{compared_case.name}"
    expect(displayed_case.draft_deadline.text).to eq compared_case.internal_deadline
    expect(displayed_case.external_deadline.text)
        .to eq compared_case.external_deadline
    expect(displayed_case.status.text).to eq compared_case.status

    expect(displayed_case.who_its_with.text).to eq who_its_with || compared_case.who_its_with
  end

  def validate_offender_sar_related_cases_fields_displayed(display_case, compared_case, extra_request_detail)
    expect(display_case.number.text).to eq "Case number #{compared_case.number}"
    expect(display_case.type.text).to eq "Offender SAR "
    expect(display_case.request_detail.text)
        .to eq "#{compared_case.subject} #{extra_request_detail}"
    expect(display_case.status.text).to eq compared_case.decorate.status
    expect(display_case.who_its_with.text).to eq compared_case.decorate.who_its_with
    expect(display_case.external_deadline.text)
        .to eq compared_case.decorate.external_deadline
  end
end
