Capybara.add_selector(:multi_case_id) do
  xpath { |id| "//*[@id=\"case_foi_#{id}\"]|//*[@id=\"case_sar_#{id}\"]" }
end
