def select_random_exemption
  excemption_options = cases_close_page.exemptions.exemption_options
  # select a random exemption
  total_number_exemptions = excemption_options.count

  # choose a random exemption, but not exemption[0] because that is not valid for NCND
  random_exemption = Random.new
                        .rand(1..(total_number_exemptions - 1))
  expect(excemption_options.size > 1).to eq true
  scroll_to excemption_options[random_exemption]
  excemption_options[random_exemption].click(wait: 10)

  excemption_options[random_exemption].text
end
