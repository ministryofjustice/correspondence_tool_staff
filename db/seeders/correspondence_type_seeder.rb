class CorrespondenceTypeSeeder

  def seed!
    puts "----Seeding Correspondence Types----"

    rec = CorrespondenceType.find_by(abbreviation: 'FOI')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Freedom of information request',
                abbreviation: 'FOI',
                escalation_time_limit: 3,
                internal_time_limit: 10,
                external_time_limit: 20,
                deadline_calculator_class: 'BusinessDays')

    rec = CorrespondenceType.find_by(abbreviation: 'SAR')
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: 'Subject Access Request',
                abbreviation: 'SAR',
                escalation_time_limit: -1,
                internal_time_limit: 10,
                external_time_limit: 30,
                deadline_calculator_class: 'CalendarDays')
  end
end
