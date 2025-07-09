require "rails_helper"

describe "cases/case_history.html.slim", type: :view do
  let!(:transition) { create(:case_transition_assign_to_new_team).decorate }
  let!(:case_transitions) { PaginatingDecorator.new(CaseTransition.all.page) }

  before do
    render partial: "cases/case_history",
           locals: { case_transitions: }
  end

  it "displays the section heading" do
    partial = case_history_section(rendered)

    expect(partial.section_heading.text).to eq "Case history"
  end

  it "displays date, user, team and event details" do
    partial_row = case_history_section(rendered).rows.last

    expect(partial_row.action_date.native.inner_html).to eq transition.action_date
    expect(partial_row.user.native.inner_html).to eq transition.user_name
    expect(partial_row.team.native.inner_html).to eq transition.user_team
    expect(partial_row.details.native.inner_html).to eq "<p>#{transition.event_and_detail}</p>"
  end

  describe "pagination" do
    it "renders the paginator" do
      expect(response).to have_rendered("kaminari/_paginator")
    end
  end
end
