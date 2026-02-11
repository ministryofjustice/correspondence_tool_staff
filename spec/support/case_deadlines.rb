def generate_start_date(month, day)
  current_year = Date.current.year
  chosen_year = if Date.new(current_year, month, day) > Time.zone.today
                  current_year - 1
                else
                  current_year
                end
  [chosen_year, Date.civil(chosen_year, month, day)]
end

def get_expected_deadline(base_date)
  expected_deadline = base_date
  expected_deadline = expected_deadline.tomorrow while !expected_deadline.workday? || BankHolidays.bank_holiday?(expected_deadline)
  expected_deadline
end
