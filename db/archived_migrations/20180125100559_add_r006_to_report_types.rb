class AddR006ToReportTypes < ActiveRecord::Migration[5.0]
  class ReportType < ApplicationRecord
  end

  def up
    rt = ReportType.find_by(abbr: "R006")
    if rt.nil?
      ReportType.create!(abbr: "R006", full_name: "Business unit map", class_name: "Stats::R006KiloMap", custom_report: false, seq_id: 9999)
    end
  end

  def down
    ReportType.find_by_abbr!("R006").destroy
  end
end
