require "rails_helper"

feature "SAR Case creation by a manager" do
  given(:responder)       { find_or_create(:foi_responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { find_or_create :disclosure_bmt_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
    login_as manager
    cases_page.load
  end

  scenario "creating a case that does not need clearance", js: true do
    create_sar_case_step

    responding_team = responder.responding_teams.first
    assign_case_step business_unit: responding_team

    # Clearance level should display deputy director
    expect(cases_show_page.clearance_levels.basic_details.deputy_director.text)
      .to include responding_team.team_lead
  end

  scenario "creating a non-trigger SAR case with only uploaded files", js: true do
    request_attachment = Rails.root.join("spec/fixtures/request-1.pdf")
    create_sar_case_step(message: "",
                         uploaded_request_files: [request_attachment])

    responding_team = responder.responding_teams.first
    assign_case_step business_unit: responding_team

    # Clearance level should display deputy director
    expect(cases_show_page.clearance_levels.basic_details.deputy_director.text)
      .to include responding_team.team_lead
  end

  scenario "creating a case that needs clearance", js: true do
    create_sar_case_step flag_for_disclosure: true

    new_case = Case::Base.last
    expect(new_case.requires_clearance?).to be true
  end

  # scenario 'creating a case with request attachments', js: true  do
  #   stub_s3_uploader_for_all_files!
  #   request_attachment = Rails.root.join('spec', 'fixtures', 'request-1.pdf')

  #   create_sar_case_step uploaded_request_files: [request_attachment]

  #   new_case = Case::Base.last
  #   request_attachment = new_case.attachments.request.first
  #   expect(request_attachment.key).to match %{/request-1.pdf$}
  # end
end
