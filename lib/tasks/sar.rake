def get_sar_category
  if CorrespondenceType.find_by_abbreviation("SAR").nil?
    CorrespondenceType.create!(
      name: "Subject Access Request",
      abbreviation: "SAR",
      internal_time_limit: 10,
      external_time_limit: 1,
      escalation_time_limit: 0,
      extension_time_limit: 2,
      extension_time_default: 1,
      deadline_calculator_class: "CalendarMonths",
    )
  else
    CorrespondenceType.sar
  end
end

namespace :sar do
  desc "create a dummy SAR case"
  task create: :environment do
    category = get_sar_category
    Timecop.freeze Time.zone.now - 24.hours do
      kase = Case::SAR::Standard.new
      kase.name = Faker::Name.name
      kase.email = Faker::Internet.email(name: kase.name)
      kase.subject = Faker::Company.catch_phrase
      kase.message = Faker::Lorem.paragraph(
        sentence_count: 10,
        supplemental: true,
        random_sentences_to_add: 10,
      )
      kase.category = category
      kase.received_date = Time.zone.yesterday
      kase.postal_address = "2 Vinery Way\nLondon\nW6 0LQ"
      kase.subject_full_name = Faker::Name.name
      kase.subject_type = "staff"
      kase.third_party = true
      kase.requester_type = "journalist"
      kase.delivery_method = "sent_by_email"
      kase.save!
      puts "Case no #{kase.number} created with id #{kase.id}"
    end
  end

  desc "Auto-closes long-term paused/stopped SAR cases"
  task auto_close_paused: :environment do
    CaseAutoCloseService.call(dryrun: false)
  end

  namespace :offender do
    desc "Close rejected offender SARs that were received over the deadline"
    task close_expired_rejected: :environment do
      Case::SAR::Offender.close_expired_rejected
    end
  end
end
