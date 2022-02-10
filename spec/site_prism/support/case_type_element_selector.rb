Capybara.add_selector(:case_form_element) do
  xpath { |id| "//*[@id=\"foi_#{id}\"]|//*[@id=\"sar_#{id}\"]|//*[@id=\"offender_sar_#{id}\"]|//*[@id=\"offender_sar_complaint_#{id}\"]|//*[@id=\"ico_#{id}\"]|//*[@id=\"ico_foi_#{id}\"]|//*[@id=\"ico_sar_#{id}\"]|//*[@id=\"overturned_foi_#{id}\"]|//*[@id=\"overturned_sar_#{id}\"]|//*[@id=\"sar_internal_review_#{id}\"]" }
end
