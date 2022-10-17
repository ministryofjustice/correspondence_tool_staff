class TestMigration4 < ActiveRecord::DataMigration
  def up
    execute <<-EOF
      UPDATE warehouse_case_reports wcr
      SET test_field_4 = 'test 4'
    EOF
  end
end