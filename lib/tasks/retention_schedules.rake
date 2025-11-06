def case_with_retention_schedule(case_type:, state:, planned_destruction_date:)
  kase = FactoryBot.create(
    case_type,
    retention_schedule:
    RetentionSchedule.new(
      state:,
      planned_destruction_date:,
    ),
  )
  kase.save!
  kase
end

def is_on_production?
  ENV["ENV"].present? && ENV["ENV"] == "prod"
end

namespace :retention_schedules do
  desc "create a dummy Offender SAR with retention schedules case"
  task create: :environment do
    if is_on_production?
      puts "Cannot run this command on production environment!"
    else
      puts "Seeding some cases with retention_schedules"
      states = %w[destroy destroy review retain not_set review] * 3

      count = 0
      states.each do |state|
        case_with_retention_schedule(
          case_type: :offender_sar_case,
          state:,
          planned_destruction_date: (Time.zone.today - (3.months + rand(1..10).days)),
        )

        count += 1
      end
      puts "Number of cases seeded: #{count}"
    end
  end

  desc "Adds retention_schedules to existing closed cases"
  task :add_rs_to_existing_branston_cases, [:batch_size] => [:environment] do |_, args|
    puts "\n*** Adding Retention Schedules to existing closed Branston cases ***"

    errors = []
    off_sar_count = 0
    off_sar_complaint_count = 0
    already_had_rs = 0

    allready_had_rs_nums = []

    all_closed_cases = Case::SAR::Offender.where(current_state: :closed).count
    complaints = Case::SAR::OffenderComplaint.where(current_state: :closed).count

    # makes progressbar more accurate as it discounts linked complaints
    # as complaints don't exist in isolation
    percent = ((all_closed_cases + complaints) / 100).round
    # percent = (complaints) / 100 .round
    percent_counter = 0
    progressbar = ProgressBar.create!
    start = Time.zone.now

    kases = Case::SAR::Offender.where(current_state: :closed).includes(:transitions)

    puts "Kases count: #{kases.count}"

    batch_size = args.fetch(:batch_size, 500).to_i

    puts "Batch size: #{batch_size}"

    kases.find_each(batch_size:) do |kase|
      if kase.retention_schedule.blank?
        percent_counter += 1
        begin
          service = RetentionSchedules::AddScheduleService.new(
            kase:, user: nil,
          )
          service.call

          off_sar_count += 1 if kase.offender_sar?
          off_sar_complaint_count += 1 if kase.offender_sar_complaint?
        rescue StandardError => e
          errors << "Case #{kase.id} errored when adding retention_schedule\n" \
            "Error details: #{e.message}"
        ensure
          if percent_counter == percent
            progressbar.increment
            percent_counter = 0
          end
        end
      else
        allready_had_rs_nums << kase.number
        already_had_rs += 1
      end
    end
    puts "\nTotal updated cases: #{off_sar_count + off_sar_complaint_count}"
    puts "-------------------------"
    puts "Offender SAR total: #{off_sar_count}"
    puts "Offender SAR complaint total: #{off_sar_complaint_count}"
    puts "-------------------------"
    puts "#{already_had_rs} cases already had retention schedules"
    puts "#{allready_had_rs_nums} case nums that already had rs"
    puts "Job took: #{Time.zone.now - start} seconds to run"

    puts "\n Case errors: \n--------------\n\n" if errors.any?
    errors.each { |error| puts error }
  end

  desc "Removes Commissioning Documents uploaded to S3 that should be destroyed"
  task remove_expired_documents: :environment do
    # Get all
  end
end
