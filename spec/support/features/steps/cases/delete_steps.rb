def delete_case_step(kase:, has_linked_case: false)
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page).to have_delete_case

  cases_show_page.delete_case.click

  expect(confirm_destroy_page).to be_displayed
  expect(confirm_destroy_page).to have_reason_for_deletion

  if has_linked_case
    confirm_destroy_page.fill_in_delete_reason(delete_reason: "testing delete case")
    confirm_destroy_page.confirm_button.click

    expect(confirm_destroy_page)
      .to have_content(I18n.t("activerecord.errors.models.case.attributes.related_case_links.not_empty"))
    expect(confirm_destroy_page).to have_reason_for_deletion
    expect(confirm_destroy_page.reason_for_deletion).to have_content("testing delete case")
  else
    confirm_destroy_page.confirm_button.click
    # Without a reason for deletion, page debounces back to user
    expect(confirm_destroy_page).to have_reason_for_deletion_error

    confirm_destroy_page.fill_in_delete_reason(delete_reason: "testing delete case")
    confirm_destroy_page.confirm_button.click

    expect(open_cases_page).to be_displayed

    sleep 2

    expect(open_cases_page.notices.first.heading.text)
      .to eq "You have deleted case #{kase.number}."
    expect(open_cases_page.case_numbers).not_to include(kase.number)
  end
end
