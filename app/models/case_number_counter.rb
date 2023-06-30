# == Schema Information
#
# Table name: case_number_counters
#
#  id      :integer          not null, primary key
#  date    :date             not null
#  counter :integer          default(0)
#

class CaseNumberCounter < ApplicationRecord
  def self.next_for_date(date)
    find_or_create_by!(date:)
    update_sql = <<~EOSQL
      UPDATE case_number_counters
        SET counter = counter + 1
        WHERE date = ?
        RETURNING counter;
    EOSQL
    sane_update_sql = sanitize_sql_array([update_sql, date])
    connection.select_value(sane_update_sql).to_i
  end
end
