namespace :demo do
  desc "Sets specified case to be visible by Press office: rake demo:viz[170821004]"
  task :press, [:case_num] => :environment do |_task, args|
    update_case_dates(args[:case_num], 1)
  end

  desc "Sets specified case to be respondable by kilo: rake demo:kilo[170823004]"
  task :kilo, [:case_num] => :environment do  |_task, args|
    update_case_dates(args[:case_num], 4)
  end
end

def update_case_dates(case_num, biz_days_ago)
  kase = Case::Base.find_by!(number: case_num)
  print_case(kase, "Original State")
  date = biz_days_ago.business_days.ago
  update_dates(kase, date)
  print_case(kase, "Updated State")
end

def update_dates(kase, date)
  kase.created_at = kase.received_date = date
  kase.escalation_deadline = kase.deadline_calculator.escalation_deadline
  kase.internal_deadline = kase.deadline_calculator.internal_deadline
  kase.external_deadline = kase.deadline_calculator.external_deadline
  kase.save!
end

def print_case(kase, heading)
  puts " >>>> #{heading} <<<<<"
  puts sprintf("%20s: %s", "created_at", kase.created_at.strftime("%Y-%m-%d %H:%M:%S"))
  puts sprintf("%20s: %s", "received_date", kase.received_date.strftime("%Y-%m-%d %H:%M:%S"))
  puts sprintf("%20s: %s", "escalation_deadline", kase.escalation_deadline.strftime("%Y-%m-%d %H:%M:%S"))
  puts sprintf("%20s: %s", "internal_deadline", kase.internal_deadline.strftime("%Y-%m-%d %H:%M:%S"))
  puts sprintf("%20s: %s", "external_deadline", kase.external_deadline.strftime("%Y-%m-%d %H:%M:%S"))
end
