class TestMigration3 < ActiveRecord::DataMigration
  def up
    execute <<-EOF
      UPDATE warehouse_case_reports wcr
      SET test_field_3 = 'test 3'
    EOF
  end
end