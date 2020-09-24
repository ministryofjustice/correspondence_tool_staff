module CaseFilter
  class CaseMultiChoicesFilterBase < CaseFilterBase

    class << self
      def identify
        if filter_attributes.empty?
          raise '#dentify should be defined in sub-class of CaseMultiChoicesFilterBase'
        else
          filter_attributes[0]
        end
      end

      def set_params(params)
        allow_params = {}
        filter_attributes.each do | filter_attribute |
          allow_params[filter_attribute] = []
        end
        params.permit(**allow_params)
      end

      def filter_fields(filter_fields)
        filter_attributes.each do | filter_attribute |
          filter_fields[filter_attribute] = [:string, array: true, default: []]
        end
      end

      def template_name
        'filter_multiple_choices'
      end
    end

  end
end
