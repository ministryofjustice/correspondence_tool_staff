require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe '#warehouse_closed_report' do
    context 'on save' do
      it 'executes' do
        kase = create :foi_case, name: 'initial name to be changed'


        case_report = Warehouse::CasesReport.find_by(case_id: kase.id)

        expect(case_report.case_id).to eq kase.id
        expect(case_report.name).to eq 'initial name to be changed'

        kase.name = 'WHat just happpened'
        kase.save!
        case_report.reload
        expect(case_report.name).to eq 'WHat just happpened'



        #
        #
        # csv_exporter = CSVExporter.new(kase)
        # result = csv_exporter.to_csv
        # puts "result: #{result.inspect}"
        # fields = CSVExporter::CSV_COLUMN_HEADINGS.map{|f|f.parameterize.underscore}.join(',')
        # fields += 'case_id'
        #
        # result << kase.id
        #
        # insert_sql = "insert into warehouse_cases_report (#{fields}) values (#{result.join(',').chomp(',')})"
        # puts "\nSQL: #{insert_sql.inspect}\n"
        # sql_result = ActiveRecord::Base.connection.execute insert_sql
        # puts "sql_result: #{sql_result.inspect}"
      end
    end

    context 'on update' do
      it 'executes' do
        #model.update!(comment: 'Edited the comment')
      end
    end

    context 'on destroy' do
      it 'executes' do
        #model.destroy!
      end
    end

    context 'on delete' do
      it 'executes' do
        #model.delete
      end
    end
  end
end
