require "rails_helper"

feature "Generate an acknowledgement letter by a responder" do
  given(:responder) { find_or_create :branston_user }
  given!(:letter_template) { find_or_create :letter_template }
  given(:offender_sar_complaint) { create(:offender_sar_complaint).decorate }
  given(:offender_sar_complaint_waiting) { create(:offender_sar_complaint, :waiting_for_data, name: "Bob").decorate }

  background do
    login_as responder
  end

  context "responder can choose a template and view the rendered letter" do
    scenario "when the case has just been created" do
      cases_show_page.load(id: offender_sar_complaint.id)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page).to have_content "To be assessed"
      expect(cases_show_page).to have_content "Send acknowledgement letter"
    end

    scenario 'and when a case is in "waiting for data" status', :js do
      cases_show_page.load(id: offender_sar_complaint_waiting.id)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page).to have_content "Mark as ready for vetting"
      expect(cases_show_page).to have_content "Send acknowledgement letter"
      click_on "Send acknowledgement letter"

      expect(cases_new_letter_page).to be_displayed

      cases_new_letter_page.new_letter.first_option.click
      click_on "Continue"

      expect(cases_show_letter_page).to be_displayed
      expect(cases_show_letter_page).to have_content "Thank you for your offender subject access request, Bob"

      click_on "Save as Word"
      expect(cases_show_letter_page).to be_displayed
      sleep 1
      output_files = Dir["#{Rails.root}/acknowledgement.docx"]
      expect(output_files.length).to eq 1
      File.delete(output_files.first)
    end
  end
end
