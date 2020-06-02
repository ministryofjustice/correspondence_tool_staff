def generate_start_date(month, day)
    current_year = Date.current.year     
    if Date.new(current_year, month, day) > Date.today
        chosen_year = current_year-1
    else
        chosen_year = current_year
    end
    [chosen_year, Date.civil(chosen_year, month, day)]
end

def get_expected_deadline(base_date)
    expected_deadline = base_date
    while !expected_deadline.workday? || expected_deadline.bank_holiday?
        expected_deadline = expected_deadline.tomorrow
    end
    expected_deadline
end
