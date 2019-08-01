class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  after_commit :warehouse

  def warehouse
    Warehouse::CasesReport.sync(self)
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
