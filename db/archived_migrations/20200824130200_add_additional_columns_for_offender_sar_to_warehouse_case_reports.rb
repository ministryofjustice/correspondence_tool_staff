class AddAdditionalColumnsForOffenderSARToWarehouseCaseReports < ActiveRecord::Migration[5.2]
  def change
    %w[
      number_of_days_taken
      number_of_exempt_pages
      number_of_final_pages
      third_party_company_name
    ].each do |field|
      if field == "third_party_company_name"
        add_column :warehouse_case_reports, field, :string
      else
        add_column :warehouse_case_reports, field, :integer
      end
    end
  end
end
