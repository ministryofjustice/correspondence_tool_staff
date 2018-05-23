Capybara.add_selector(:case_form_element) do
  xpath { |id| "//*[@id=\"case_foi_#{id}\"]|//*[@id=\"case_sar_#{id}\"]" }
end
