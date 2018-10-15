require 'rails_helper'

feature 'ICO case creation' do

  given(:responder)                   { find_or_create(:foi_responder) }
  given(:responding_team)             { create :responding_team, responders: [responder] }
  given(:manager)                     { find_or_create :disclosure_bmt_user }
  given(:managing_team)               { create :managing_team, managers: [manager] }
  given(:original_foi)                { create :closed_case }
  given(:related_foi)                 { create :closed_case }
  given(:another_related_foi)         { create :closed_case }
  given(:related_timeliness_review)   { create :closed_timeliness_review }
  given(:related_timeliness_review_2) { create :closed_timeliness_review }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
    original_foi
    related_foi
    another_related_foi
    related_timeliness_review
    related_timeliness_review_2
    login_as manager
    cases_page.load
  end

  context 'creating an ICO appeal' do
    scenario ' - linking Original case', js: true do
      cases_new_ico_page.load

      cases_new_ico_page.form.original_case_number.set ''
      cases_new_ico_page.form.link_original_case.click
      expect(cases_new_ico_page.form.original_case_number_error.text)
        .to eq 'Enter original case number'

      cases_new_ico_page.form.original_case_number.set original_foi.number
      cases_new_ico_page.form.link_original_case.click
      expect(cases_new_ico_page.form).to have_no_original_case_number_error
      expect(cases_new_ico_page.form.original_case.linked_records.first.link)
        .to have_copy original_foi.number
    end

    scenario ' - removing Original case', js: true do
      cases_new_ico_page.load

      cases_new_ico_page.form.original_case_number.set original_foi.number
      cases_new_ico_page.form.link_original_case.click

      expect(cases_new_ico_page.form.original_case).to have_linked_records(count: 1)
      cases_new_ico_page.form.original_case.linked_records.first.remove_link.click

      expect(cases_new_ico_page.form).to have_no_original_case
      expect(cases_new_ico_page.form.original_case_number).to be_visible
      expect(cases_new_ico_page.form).to have_no_related_case_number
    end

    scenario ' - linking relate case', js: true do
      cases_new_ico_page.load

      cases_new_ico_page.form.original_case_number.set original_foi.number
      cases_new_ico_page.form.link_original_case.click

      cases_new_ico_page.form.related_case_number.set 'abcd13'
      cases_new_ico_page.form.link_related_case.click
      expect(cases_new_ico_page.form.related_case_number_error.text)
        .to eq 'Related case not found'

      cases_new_ico_page.form.related_case_number.set related_foi.number
      cases_new_ico_page.form.link_related_case.click
      expect(cases_new_ico_page.form).to have_related_cases
      expect(cases_new_ico_page.form.related_cases).to have_linked_records
      expect(cases_new_ico_page.form.related_cases.linked_records.first.link)
        .to have_copy related_foi.number
    end


    scenario ' - removing related case', js: true do
      cases_new_ico_page.load

      cases_new_ico_page.form.original_case_number.set original_foi.number
      cases_new_ico_page.form.link_original_case.click

      cases_new_ico_page.form.related_case_number.set related_foi.number
      cases_new_ico_page.form.link_related_case.click
      expect(cases_new_ico_page.form.related_cases)
        .to have_linked_records(count: 1)

      cases_new_ico_page.form.related_case_number.set another_related_foi.number
      cases_new_ico_page.form.link_related_case.click
      expect(cases_new_ico_page.form.related_cases)
        .to have_linked_records(count: 2)

      cases_new_ico_page.form.related_cases.linked_records.first.remove_link.click
      expect(cases_new_ico_page.form.related_cases)
        .to have_linked_records(count: 1)

      cases_new_ico_page.form.related_cases.linked_records.first.remove_link.click
      expect(cases_new_ico_page.form).to have_no_related_cases
    end
  end
end
