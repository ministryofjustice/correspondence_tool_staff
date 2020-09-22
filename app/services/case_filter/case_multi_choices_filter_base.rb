module CaseFilter
  class CaseMultiChoicesFilterBase < CaseFilterBase

    def self.set_params(params)
      allow_params = {}
      filter_attributes.each do | filter_attribute |
        allow_params[filter_attribute] = []
      end
      params.permit(**allow_params)
    end

    def self.filter_fields(filter_fields)
      filter_attributes.each do | filter_attribute |
        filter_fields[filter_attribute] = [:string, array: true, default: []]
      end
    end

    def self.template_name
      'filter_multiple_choices'
    end

  end
end
