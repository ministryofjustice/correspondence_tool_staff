require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
feature "filtering cases" do
  before(:all) do
    login_as create(:manager)
    @unassigned_case                                            = create :case
    @awaiting_responder_case                                    = create :awaiting_responder_case
    @drafting_case                                              = create :accepted_case
    @awaiting_dispatch_case                                     = create :case_with_response
    @pending_dacu_clearance_case                                = create :pending_dacu_clearance_case
    @unaccepted_pending_dacu_clearance_case                     = create :unaccepted_pending_dacu_clearance_case
    @pending_dacu_clearance_case_flagged_for_press              = create :pending_dacu_clearance_case_flagged_for_press
    @pending_dacu_clearance_case_flagged_for_press_and_private  = create :pending_dacu_clearance_case_flagged_for_press_and_private
    @pending_press_clearance_case                               = create :pending_press_clearance_case
    @pending_private_clearance_case                             = create :pending_private_clearance_case
  end

  after(:all) do
    DbHousekeeping.clean(seed: true)
  end

  before { sign_in create(:manager) }

  let(:all_case_numbers) do
    case_nos(@unassigned_case,
             @awaiting_responder_case,
             @drafting_case,
             @awaiting_dispatch_case,
             @pending_dacu_clearance_case,
             @unaccepted_pending_dacu_clearance_case,
             @pending_dacu_clearance_case_flagged_for_press,
             @pending_dacu_clearance_case_flagged_for_press_and_private,
             @pending_press_clearance_case,
             @pending_private_clearance_case)
  end

  scenario "no checkboxes selected before filter applied", js: true do
    open_cases_page.load
    open_cases_page.case_filters.filter_cases_link.click
    open_cases_page.case_filters.filter_open_status_link.click
    open_cases_page.case_filters.apply_filters_button.click
    expect(open_cases_page.case_numbers).to match_array(all_case_numbers)
  end

  scenario "filter just unassigned cases", js: true do
    open_cases_page.load
    open_cases_page.case_filters.filter_cases_link.click
    open_cases_page.case_filters.filter_open_status_link.click
    open_cases_page.choose_state("unassigned")
    open_cases_page.case_filters.apply_filters_button.click

    expect(open_cases_page.case_numbers).to eq [@unassigned_case.number]
  end

  scenario "filter on unassigned, drafting and awaiting_dispatch cases", js: true do
    open_cases_page.load
    open_cases_page.case_filters.filter_cases_link.click
    open_cases_page.case_filters.filter_open_status_link.click
    open_cases_page.choose_state("unassigned")
    open_cases_page.choose_state("drafting")
    open_cases_page.choose_state("awaiting_dispatch")
    open_cases_page.case_filters.apply_filters_button.click

    expected_case_nos = case_nos(@unassigned_case, @awaiting_dispatch_case, @drafting_case)
    expect(open_cases_page.case_numbers).to match_array(expected_case_nos)
  end

  scenario "just pending dacu clearance", js: true do
    open_cases_page.load
    open_cases_page.case_filters.filter_cases_link.click
    open_cases_page.case_filters.filter_open_status_link.click
    open_cases_page.choose_state("pending_dacu_clearance")
    open_cases_page.case_filters.apply_filters_button.click

    expected_case_nos = case_nos(@pending_dacu_clearance_case,
                                 @unaccepted_pending_dacu_clearance_case,
                                 @pending_dacu_clearance_case_flagged_for_press,
                                 @pending_dacu_clearance_case_flagged_for_press_and_private)

    expect(open_cases_page.case_numbers).to match_array(expected_case_nos)
  end

  def case_nos(*args)
    result = []
    args.each do |kase|
      result << kase.number
    end
    result
  end
end
# rubocop:enable RSpec/BeforeAfterAll
