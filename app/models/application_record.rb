class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # NOTE: Evaluate individual attributes to allow multi-step wizard
  # based on individual attributes being gradually completed
  # https://stackoverflow.com/questions/4804591/rails-activerecord-validate-single-attribute
  def valid_attributes?(attributes)
    attributes.each_key do |attribute|
      self.class.validators_on(attribute).each do |validator|
        skip = false

        if validator.options[:if].is_a?(Proc)
          skip = !instance_exec(&validator.options[:if])
        end

        if validator.options[:unless].is_a?(Proc)
          skip = instance_exec(&validator.options[:unless])
        end

        next if skip

        validator.validate_each(self, attribute, send(attribute))
      end
    end
    errors.none?
  end
end
