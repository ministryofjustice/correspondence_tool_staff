class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def valid_attributes?(attributes)
    attributes.each_key do |attribute|
      self.class.validators_on(attribute).each do |validator|
        validator.validate_each(self, attribute, send(attribute))
      end
    end
    errors.none?
  end
end
