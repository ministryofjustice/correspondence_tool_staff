class AddReportCategoryToCorrespondenceType < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.each do |ct|
      ct.report_category_name = ''
      ct.save!
    end
    ['FOI', 'SAR'].each do |ct_abbr|
      ct = CorrespondenceType.find_by!(abbreviation: ct_abbr)
      ct.report_category_name = "#{ct_abbr} report"
      ct.save!
    end
  end
end
