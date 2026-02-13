require "rails_helper"
require "capybara/dsl"

# rubocop:disable RSpec/BeforeAfterAll
describe "cases/filters/incoming.html.slim", type: :view do
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:case1) do
    create(:assigned_case, :flagged,
           approving_team: team_dacu_disclosure,
           name: "Joe Smith",
           subject: "Prison Reform",
           message: "message number 1").decorate
  end
  let(:case2) do
    create(:assigned_case, :flagged,
           approving_team: team_dacu_disclosure,
           name: "Jane Doe",
           subject: "Court Reform",
           message: "message number 2").decorate
  end
  let(:further_clearance_case) do
    create(:assigned_case, :flagged, :further_clearance_requested,
           approving_team: team_dacu_disclosure,
           name: "Questioning Jim",
           subject: "Reform Reform",
           message: "message number 3").decorate
  end
  let(:request) do
    instance_double ActionDispatch::Request,
                    path: "/cases/incoming",
                    fullpath: "/cases/incoming",
                    query_parameters: {},
                    params: {}
  end

  before do
    DbHousekeeping.clean(seed: true)
    assign(:homepage_nav_manager, GlobalNavManager.new(disclosure_specialist,
                                                       request,
                                                       Settings.homepage_navigation.pages))
    allow(controller).to receive(:current_user).and_return(disclosure_specialist)
  end

  after(:all) do
    DbHousekeeping.clean(seed: true)
  end

  it "displays the cases given it" do
    case1
    case2
    further_clearance_case
    cases = PaginatingDecorator.new(Case::Base.all.page.order(:id))
    assign(:cases, cases)

    cases.each do |kase|
      allow_case_policies_in_view(kase, :unflag_for_clearance?)
      disallow_case_policies_in_view(kase, :can_add_case?)
    end

    sign_in disclosure_specialist

    render
    incoming_cases_page.load(rendered)

    first_case = incoming_cases_page.case_list[0]
    expect(first_case.number.text).to eq "Case number #{case1.number}"
    expect(first_case.request.name.text).to eq "Joe Smith | member_of_the_public"
    expect(first_case.request.subject.text).to eq "Prison Reform"
    expect(first_case.request.message.text).to eq "message number 1"
    expect(first_case.actions.take_on_case.text).to eq "Take case on"
    expect(first_case.actions.de_escalate_link.text).to eq "De-escalate"

    second_case = incoming_cases_page.case_list[1]
    expect(second_case.number.text).to eq "Case number #{case2.number}"
    expect(second_case.request.name.text).to eq "Jane Doe | member_of_the_public"
    expect(second_case.request.subject.text).to eq "Court Reform"
    expect(second_case.request.message.text).to eq "message number 2"
    expect(second_case.actions.take_on_case.text).to eq "Take case on"
    expect(second_case.actions.de_escalate_link.text).to eq "De-escalate"

    third_case = incoming_cases_page.case_list[2]
    expect(third_case.number.text).to eq "Case number #{further_clearance_case.number}"
    expect(third_case.request.name.text).to eq "Questioning Jim | member_of_the_public"
    expect(third_case.request.subject.text).to eq "Reform Reform"
    expect(third_case.request.message.text).to eq "message number 3"
    expect(third_case.actions.take_on_case.text).to eq "Take case on"
    expect(third_case.actions.de_escalate_link.text).to eq "De-escalate"
    expect(third_case.actions.requested_by.text).to eq "Further clearance requested"
  end

  describe "pagination" do
    it "renders the paginator" do
      assign(:cases, Case::Base.none.page.decorate)
      render
      expect(response).to have_rendered("kaminari/_paginator")
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
