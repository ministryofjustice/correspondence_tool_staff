class UpdateRequestMethodWarehouse < ActiveRecord::DataMigration
  def up
    # execute <<-EOF
    #   UPDATE warehouse_case_reports wcr
    #   SET request_method = properties->>'request_method'
    #   FROM cases c
    #   WHERE wcr.case_id = c.id;
    # EOF
  end
end
