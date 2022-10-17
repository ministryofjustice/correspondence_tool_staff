class TestMigration2 < ActiveRecord::DataMigration
  def up
    execute <<-EOF
      UPDATE warehouse_case_reports wcr
      SET request_method = 'test'
      FROM cases c
      WHERE wcr.case_id = c.id;
    EOF
  end
end