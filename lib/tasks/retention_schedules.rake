require 'pry'

namespace :retention_schedules do
  desc 'create a dummy Offender Sar with retention schedules case'
  task :create => :environment do
    if is_on_production?
      puts "Cannot run this command on production environment!"
    else
      puts "Seeding some cases with retention_schedules"
      states = ['destroy', 'destroy', 'review', 'retain', 'not_set', 'review'] * 3

      count = 0
      states.each do |state|

        case_with_retention_schedule(
          case_type: :offender_sar_case,
          state: state,
          planned_destruction_date: (Date.today - (3.months + rand(1..10).days))
        )

        count += 1
      end
      puts "Number of cases seeded: #{count}"
    end
  end
  
  desc 'Adds retention_schedules to existing closed cases'
  task :add_rs_to_existing_branston_cases => [:environment] do
    if FeatureSet.branston_retention_scheduling.enabled?
      puts "\n*** Adding Retention Schedules to existing closed Branston cases ***"

      errors = []
      off_sar_count = 0
      off_sar_complaint_count = 0
      already_had_rs = 0

      percent = (Case::SAR::Offender.where(current_state: :closed).count / 100).round
      percent_counter = 0
      progressbar = ProgressBar.create

      
      Case::SAR::Offender.where(current_state: :closed).includes(:transitions).find_each do | kase |
        if kase.retention_schedule.nil?
          percent_counter += 1
          begin 
            service = RetentionSchedules::AddScheduleService.new(
              kase: kase
            )
            service.call
            
            off_sar_count += 1 if kase.offender_sar?
            off_sar_complaint_count += 1 if kase.offender_sar_complaint?

          rescue => e
            errors << "Case #{kase.id} errored when adding retention_schedule\n" +
                      "Error details: #{e.message}"
          ensure
            if percent_counter == percent
              progressbar.increment
              percent_counter = 0
            end
          end
        else
          already_had_rs += 1 
        end
      end
    else
      puts "Cannot run task as feature unavailable on this environment"
    end
    puts "\nTotal updated cases: #{off_sar_count + off_sar_complaint_count}"
    puts "-------------------------"
    puts "Offender SAR total: #{off_sar_count}"
    puts "Offender SAR complaint total: #{off_sar_complaint_count}"
    puts "-------------------------"
    puts "#{already_had_rs} cases already had retention schedules"

    puts "\n Case errors: \n--------------\n\n" if errors.any?
    errors.each { |error| puts error }
  end

  def case_with_retention_schedule(case_type:, state:, planned_destruction_date:)
    kase = FactoryBot::create(
      case_type, 
      retention_schedule: 
      RetentionSchedule.new( 
        state: state, 
        planned_destruction_date: planned_destruction_date 
      ) 
    )
    kase.save
    kase
  end

  def is_on_production?
    ENV['ENV'].present? && ENV['ENV'] == 'prod'
  end
end
