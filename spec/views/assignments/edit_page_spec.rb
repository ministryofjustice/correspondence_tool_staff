require "rails_helper"

describe "assignments/edit.html.slim", type: :view do
  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  let(:responder)       { find_or_create :foi_responder }
  let(:responding_team) { responder.responding_teams.first }
  let(:awaiting_responder_case) do
    create(:awaiting_responder_case, :with_messages,
           responding_team:).decorate
  end
  let(:assignment)      { awaiting_responder_case.responder_assignment }

  it "displays the edit assignment page" do
    assign(:case, awaiting_responder_case)
    assign(:case_transitions, awaiting_responder_case.transitions.case_history.page(1).decorate)
    assign(:correspondence_type_key, awaiting_responder_case.type_abbreviation.downcase)
    assign(:assignment, assignment)

    login_as responder
    allow_case_policies_in_view awaiting_responder_case,
                                :can_add_message_to_case?,
                                :request_further_clearance?,
                                :destroy_case_link?,
                                :can_upload_request_attachment?
    disallow_case_policies_in_view awaiting_responder_case,
                                   :new_case_link?,
                                   :destroy_case_link?,
                                   :can_remove_attachment?

    render

    assignments_edit_page.load(rendered)

    page = assignments_edit_page

    expect(page.page_heading.heading.text)
        .to eq "Case subject, #{awaiting_responder_case.subject}"
    expect(page.page_heading.sub_heading.text)
        .to eq "You are viewing case number #{awaiting_responder_case.number} - #{awaiting_responder_case.pretty_type} "

    expect(page).to have_case_status

    expect(page).to have_no_ico

    expect(page).to have_case_details

    expect(page).to have_request

    expect(page.message.text).to eq awaiting_responder_case.message

    expect(page).to have_messages

    expect(page).to have_new_message

    expect(page).to have_case_history

    expect(page).to have_no_original_case_details

    expect(page).to have_accept_radio
    expect(page).to have_reject_radio

    expect(page.confirm_button.value).to eq "Confirm"
  end

  describe "ICO cases" do
    let(:awaiting_responder_case) do
      create(:awaiting_responder_ico_foi_case, :with_messages,
             responding_team:).decorate
    end
    let(:assignment_for_ico) { awaiting_responder_case.responder_assignment }

    it "displays page and sections for ICO cases" do
      assign(:case, awaiting_responder_case)
      assign(:case_transitions, awaiting_responder_case.transitions.case_history.page(1).decorate)
      assign(:correspondence_type_key, awaiting_responder_case.type_abbreviation.downcase)
      assign(:assignment, assignment_for_ico)

      login_as responder
      allow_case_policies_in_view awaiting_responder_case,
                                  :can_add_message_to_case?,
                                  :request_further_clearance?,
                                  :destroy_case_link?,
                                  :can_upload_request_attachment?
      disallow_case_policies_in_view awaiting_responder_case,
                                     :new_case_link?,
                                     :destroy_case_link?,
                                     :can_remove_attachment?

      render

      assignments_edit_page.load(rendered)

      page = assignments_edit_page

      expect(page.page_heading.heading.text)
          .to eq "Case subject, #{awaiting_responder_case.subject}"
      expect(page.page_heading.sub_heading.text)
          .to eq "You are viewing case number #{awaiting_responder_case.number} - #{awaiting_responder_case.pretty_type} "

      expect(page).to have_case_status

      expect(page).to have_ico

      expect(page.ico).to have_original_cases

      expect(page).to have_case_details

      expect(page).to have_request

      expect(page.message.text).to eq awaiting_responder_case.message

      expect(page).to have_messages

      expect(page).to have_new_message

      expect(page).to have_case_history

      expect(page).to have_original_case_details
      expect(page.original_case_details).to have_link_to_case

      expect(page).to have_accept_radio
      expect(page).to have_reject_radio

      expect(page.confirm_button.value).to eq "Confirm"
    end
  end

  describe "Overturned SARS cases" do
    let(:awaiting_responder_case) do
      create(:awaiting_responder_ot_ico_sar, :with_messages,
             responding_team:).decorate
    end
    let(:assignment_for_overturned) { awaiting_responder_case.responder_assignment }

    it "displays page and sections for ICO cases" do
      assign(:case, awaiting_responder_case)
      assign(:case_transitions, awaiting_responder_case.transitions.case_history.page(1).decorate)
      assign(:correspondence_type_key, awaiting_responder_case.type_abbreviation.downcase)
      assign(:assignment, assignment_for_overturned)

      login_as responder
      allow_case_policies_in_view awaiting_responder_case,
                                  :can_add_message_to_case?,
                                  :request_further_clearance?,
                                  :destroy_case_link?,
                                  :can_upload_request_attachment?
      disallow_case_policies_in_view awaiting_responder_case,
                                     :new_case_link?,
                                     :destroy_case_link?,
                                     :can_remove_attachment?

      render

      assignments_edit_page.load(rendered)

      page = assignments_edit_page

      expect(page.page_heading.heading.text)
          .to eq "Case subject, #{awaiting_responder_case.subject}"
      expect(page.page_heading.sub_heading.text)
          .to eq "You are viewing case number #{awaiting_responder_case.number} - #{awaiting_responder_case.pretty_type} "

      expect(page).to have_case_status

      expect(page).to have_overturned_sar

      expect(page.overturned_sar).to have_original_cases

      expect(page.overturned_sar).to have_ico_decision_section

      expect(page.overturned_sar).to have_case_details

      expect(page.overturned_sar).to have_no_request

      expect(page).to have_messages

      expect(page).to have_new_message

      expect(page).to have_case_history

      expect(page.overturned_sar).to have_original_case_details
      expect(page.overturned_sar.original_case_details).to have_link_to_case

      expect(page).to have_accept_radio
      expect(page).to have_reject_radio

      expect(page.confirm_button.value).to eq "Confirm"
    end
  end

  describe "Overturned FOI cases" do
    let(:ovt_foi_case) do
      create(:awaiting_responder_ot_ico_foi, :with_messages,
             responding_team:).decorate
    end
    let(:assignment) { awaiting_responder_case.responder_assignment }

    it "displays page and sections for ICO cases" do
      assign(:case, ovt_foi_case)
      assign(:case_transitions, ovt_foi_case.transitions.case_history.page(1).decorate)
      assign(:correspondence_type_key, ovt_foi_case.type_abbreviation.downcase)
      assign(:assignment, assignment)

      login_as responder
      allow_case_policies_in_view ovt_foi_case,
                                  :can_add_message_to_case?,
                                  :request_further_clearance?,
                                  :destroy_case_link?,
                                  :can_upload_request_attachment?
      disallow_case_policies_in_view ovt_foi_case,
                                     :new_case_link?,
                                     :destroy_case_link?,
                                     :can_remove_attachment?

      render

      assignments_edit_page.load(rendered)

      page = assignments_edit_page

      expect(page.page_heading.heading.text)
          .to eq "Case subject, #{ovt_foi_case.subject}"
      expect(page.page_heading.sub_heading.text)
          .to eq "You are viewing case number #{ovt_foi_case.number} - #{ovt_foi_case.pretty_type} "

      expect(page).to have_case_status

      expect(page).to have_overturned_foi

      expect(page.overturned_foi).to have_original_cases

      expect(page.overturned_foi).to have_ico_decision_section

      expect(page.overturned_foi).to have_case_details

      expect(page.overturned_foi).to have_no_request

      expect(page).to have_messages

      expect(page).to have_new_message

      expect(page).to have_case_history

      expect(page.overturned_foi).to have_original_case_details
      expect(page.overturned_foi.original_case_details).to have_link_to_case

      expect(page).to have_accept_radio
      expect(page).to have_reject_radio

      expect(page.confirm_button.value).to eq "Confirm"
    end
  end
end
