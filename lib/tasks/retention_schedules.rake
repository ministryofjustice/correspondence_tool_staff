namespace :retention_schedules do
  namespace :branston do
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
            planned_erasure_date: (Date.today - (3.months + rand(1..10).days))
          )

          count += 1
        end
        puts "Number of cases seeded: #{count}"
      end
    end

    def case_with_retention_schedule(case_type:, state:, planned_erasure_date:)
      kase = FactoryBot::create(
        case_type, 
        retention_schedule: 
        RetentionSchedule.new( 
          state: state, 
          planned_erasure_date: planned_erasure_date 
        ) 
      )
      kase.save
      kase
    end

    def is_on_production?
      ENV['ENV'].present? && ENV['ENV'] == 'prod'
    end
  end
end

