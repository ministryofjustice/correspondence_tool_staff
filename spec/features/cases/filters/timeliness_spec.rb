require "rails_helper"

feature "filtering cases by timeliness" do
  include PageObjects::Pages::Support

  before(:all) do
    @setup = StandardSetup.new(only_cases: %i[
      std_draft_foi
      std_draft_foi_late
      std_responded_foi
      std_responded_foi_late
      std_closed_foi
      std_closed_foi_late
      trig_draft_foi_accepted
      trig_draft_foi_accepted_late
      trig_closed_foi
      trig_closed_foi_late
    ])
  end

  after(:all) do
    DbHousekeeping.clean(seed: false)
  end

  before do
    login_step user: @setup.disclosure_bmt_user
  end

  scenario "listing cases on open cases page", js: true do
    expect(open_cases_page).to be_displayed

    expect(open_cases_page.case_numbers)
      .to match_array expected_case_numbers :std_draft_foi,
                                            :std_draft_foi_late,
                                            :std_responded_foi,
                                            :std_responded_foi_late,
                                            :trig_draft_foi_accepted,
                                            :trig_draft_foi_accepted_late

    # enable in_time filter
    open_cases_page.filter_on(:timeliness, :in_time)

    expect(open_cases_page).to be_displayed
    expect(open_cases_page.case_numbers)
      .to match_array expected_case_numbers :std_draft_foi,
                                            :std_responded_foi,
                                            :trig_draft_foi_accepted
    open_cases_page.open_filter(:timeliness)
    expect(open_cases_page.filter_timeliness_content.in_time_checkbox)
      .to be_checked

    # remove in_time filter
    open_cases_page.filter_crumb_for("In time").click

    open_cases_page.open_filter(:timeliness)
    expect(open_cases_page.filter_timeliness_content.in_time_checkbox)
      .not_to be_checked

    # enable late filter
    open_cases_page.filter_on(:timeliness, :late)

    expect(open_cases_page).to be_displayed
    expect(open_cases_page.case_numbers)
      .to match_array expected_case_numbers :std_draft_foi_late,
                                            :std_responded_foi_late,
                                            :trig_draft_foi_accepted_late
    open_cases_page.open_filter(:timeliness)
    expect(open_cases_page.filter_timeliness_content.late_checkbox)
      .to be_checked
  end
end
