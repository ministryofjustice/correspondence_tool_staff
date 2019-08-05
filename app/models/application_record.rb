class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  after_commit :warehouse

  # Add any further warehousing operations here, ideally async
  def warehouse
    if Warehouse::CasesSyncJob.sync?(self)
      Warehouse::CasesSyncJob.perform_now(self.class.to_s, self.id)
    end
  end

  def valid_attributes?(attributes)
    attributes.each do |attribute|
      self.class.validators_on(attribute).each do |validator|
        validator.validate_each(self, attribute, send(attribute))
      end
    end
    errors.none?
  end
end
