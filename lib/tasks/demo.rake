namespace :demo do

  desc 'Sets specified case to be visible by Press office: rake demo:viz[170821004]'
  task :press, [:case_num] => :environment do  | _task, args |
    case_num = args[:case_num]
    kase = Case.find_by!(number: case_num)
    print_case(kase, "Original State")
    date = 1.business_days.ago
    update_dates(kase, date)
    print_case(kase, "Updated State")
  end

  desc 'Sets specified case to be respondable by kilo: rake demo:kilo[170823004]'
  task :kilo, [:case_num] => :environment do  | _task, args |
    case_num = args[:case_num]
    kase = Case.find_by!(number: case_num)
    print_case(kase, "Original State")
    date = 4.business_days.ago
    update_dates(kase, date)
    print_case(kase, "Updated State")
  end
end


def update_dates(kase, date)
  kase.created_at = kase.received_date = date
  kase.escalation_deadline = DeadlineCalculator.escalation_deadline(kase)
  kase.internal_deadline = DeadlineCalculator.internal_deadline(kase)
  kase.external_deadline = DeadlineCalculator.external_deadline(kase)
  kase.save!
end

def print_case(kase, heading)
  puts " >>>> #{heading} <<<<<"
  puts sprintf('%20s: %s', 'created_at', kase.created_at.strftime('%Y-%m-%d %H:%M:%S'))
  puts sprintf('%20s: %s', 'received_date', kase.received_date.strftime('%Y-%m-%d %H:%M:%S'))
  puts sprintf('%20s: %s', 'escalation_deadline', kase.escalation_deadline.strftime('%Y-%m-%d %H:%M:%S'))
  puts sprintf('%20s: %s', 'internal_deadline', kase.internal_deadline.strftime('%Y-%m-%d %H:%M:%S'))
  puts sprintf('%20s: %s', 'external_deadline', kase.external_deadline.strftime('%Y-%m-%d %H:%M:%S'))
end

