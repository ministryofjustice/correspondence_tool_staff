module CaseFilter
  class CaseMultiChoicesFilterBase < CaseFilterBase

    class << self
      def identify
        if filter_attributes.empty?
          raise '#identify should be defined in sub-class of CaseMultiChoicesFilterBase'
        else
          filter_attributes.first.to_s
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

    def crumbs
      our_crumbs = []
      if applied?
        summary_text = I18n.t(
          "filters.#{self.class.identify}.#{@query.send(self.class.identify).first}"
        )
        crumb_text = I18n.t "filters.crumbs.#{self.class.identify}",
                            count: @query.send(self.class.identify).size,
                            first_value: summary_text,
                            remaining_values_count: @query.send(self.class.identify).count - 1
        params = {
          self.class.identify  => [''],
          'parent_id'          => @query.id,
        }
        our_crumbs << [crumb_text, params]
      end
      our_crumbs
    end

  end
end
