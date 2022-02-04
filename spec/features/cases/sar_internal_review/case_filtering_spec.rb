require 'rails_helper'

feature 'filtering cases' do

  before(:all) do
    login_as create(:manager)
    @unassigned_case             = create :sar_case
    @awaiting_responder_case     = create :awaiting_responder_sar
    @drafting_case               = create :accepted_sar
    @pending_dacu_clearance_case = create :pending_dacu_clearance_sar

    @sar_ir_timeliness = create(:sar_internal_review, sar_ir_subtype: 'timeliness')
    @sar_ir_compliance = create(:sar_internal_review, sar_ir_subtype: 'compliance')
  end

  after(:all) { DbHousekeeping.clean }

  before(:each) { sign_in create(:manager) }

  let(:all_case_numbers) do
    case_nos(@unassigned_case,
             @awaiting_responder_case,
             @drafting_case,
             @pending_dacu_clearance_case,
             @sar_ir_timeliness,
             @sar_ir_compliance,
             @sar_ir_timeliness.original_case,
             @sar_ir_compliance.original_case)
  end

  scenario 'no checkboxes selected before filter applied', js: true do
    open_cases_page.load
    open_cases_page.case_filters.filter_cases_link.click
    open_cases_page.case_filters.filter_open_status_link.click
    open_cases_page.case_filters.apply_filters_button.click
    expect(open_cases_page.case_numbers).to match_array(all_case_numbers)
  end


  scenario 'filter on case type SAR IR timeliness and compliance', js: true do
    open_cases_page.load
    open_cases_page.case_filters.filter_cases_link.click
    open_cases_page.case_filters.filter_type_link.click
    open_cases_page.case_filters.check("SAR - Internal review for compliance", visible: false)
    open_cases_page.case_filters.check("SAR - Internal review for timeliness", visible: false)
    open_cases_page.case_filters.apply_filters_button.click

    expected_case_nos = case_nos(@sar_ir_compliance, @sar_ir_timeliness)

    expect(open_cases_page.case_numbers).to match_array(expected_case_nos)
    expect(open_cases_page.case_numbers).to_not include(case_nos(@unassigned_case))
  end

  def case_nos(*args)
    result = []
    args.each do |kase|
      result << kase.number
    end
    result
  end
end
