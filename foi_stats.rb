require "csv"

# Generates CSV string with data for successful acceptance of cases by directorate
# Three lines per directorate showing cases accepted per day, percentage of accepted cases per day and running total of percentage accepted cases
# for the following dates and case type:
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
  csv << ["total FOI cases #{start_date} to #{end_date}", count]
  csv << ["cases not successfully accepted", no_acceptance]
  csv << []

  heading = [" ", "1 Day"]
  2.upto(20) do |i|
    heading << "#{i} Days"
  end
  heading << "Over 20 days"
  csv << heading

  results.each do |directorate, stats|
    # Raw numbers
    stats.unshift(directorate)
    csv << stats

    stats.shift
    total = stats.sum
    p total

    # individual percentages
    percentage_row = [" "]
    stats.each do |n|
      percentage_row << ((n / total.to_f) * 100.to_f).to_i
    end
    csv << percentage_row

    # overall percentages
    overall_percentage_row = [" "]
    running_total = 0
    stats.each do |n|
      running_total += n
      overall_percentage_row << ((running_total / total.to_f) * 100.to_f).to_i
    end
    csv << overall_percentage_row
  end
end
