namespace :sar do
  desc 'create a dummy SAR case'
  task :create => :environment do
    category = get_sar_category
    Timecop.freeze Time.now - 24.hours do
      kase = Case::SAR.new
      kase.name = Faker::Name.name
      kase.email = Faker::Internet.email(kase.name)
      kase.subject = Faker::Company.catch_phrase
      kase.message = Faker::Lorem.paragraph(10, true, 10)
      kase.category = category
      kase.received_date = Date.yesterday
      kase.postal_address = "2 Vinery Way\nLondon\nW6 0LQ"
      kase.subject_full_name = Faker::Name.name
      kase.subject_type = 'staff'
      kase.third_party = true
      kase.requester_type = 'journalist'
      kase.delivery_method = 'sent_by_email'
      kase.save!
      puts "Case no #{kase.number} created with id #{kase.id}"
    end

  end



  def get_sar_category
    if CorrespondenceType.find_by_abbreviation("SAR").nil?
      CorrespondenceType.create(
          name: 'Subject Access Request',
          abbreviation: 'SAR',
          internal_time_limit: 10,
          external_time_limit: 30,
          escalation_time_limit: 0,
          deadline_calculator_class: 'CalendarDays'
      )
    else
      CorrespondenceType.sar
    end
  end
end
