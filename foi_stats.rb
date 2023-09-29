require "csv"

# Generates CSV string with data for successful acceptance of cases by directorate for the following dates and case type:
start_date = Date.new(2023, 1, 1)
end_date = Date.new(2023, 8, 31)
case_type = "Case::FOI::Standard"

results = {}
count = 0
no_acceptance = 0

Case::Base.where(received_date: start_date..end_date).where(type: case_type).find_each(batch_size: 100) do |kase|
  count += 1

  acceptance = kase.transitions.where(event: "accept_responder_assignment").last
  if acceptance.blank?
    no_acceptance += 1
    next
  end

  directorate = acceptance.acting_team.directorate.name

  unless results.key?(directorate)
    results[directorate] = Array.new(21, 0)
  end

  days = DeadlineCalculator::BusinessDays.days_taken(kase.received_date, acceptance.created_at)
  if days <= 20
    results[directorate][days - 1] += 1
  else
    results[directorate][20] += 1
  end
end

CSV.generate do |csv|
  csv << ["total FOI cases 1st January 2023 to 31st August 2023", count]
  csv << ["cases not successfully accepted", no_acceptance]
  csv << []

  heading = [" ", "1 Day"]
  2.upto(20) do |i|
    heading << "#{i} Days"
  end
  heading << "Over 20 days"
  csv << heading

  results.each do |directorate, stats|
    row = stats
    row.unshift(directorate)
    csv << row
  end
end
