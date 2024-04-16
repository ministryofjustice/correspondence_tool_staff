class AddSARInternalReviewCorrespondenceType < ActiveRecord::DataMigration
  def up
    rec = CorrespondenceType.find_by(abbreviation: "SAR_INTERNAL_REVIEW")
    rec = CorrespondenceType.new if rec.nil?
    rec.update!(name: "Subject access request internal review",
                abbreviation: "SAR_INTERNAL_REVIEW",
                show_on_menu: false,
                report_category_name: "SAR report",
                escalation_time_limit: 0,
                internal_time_limit: 10,
                external_time_limit: 1,
                extension_time_limit: 2,
                extension_time_default: 1,
                deadline_calculator_class: "CalendarMonths")
  end
end
