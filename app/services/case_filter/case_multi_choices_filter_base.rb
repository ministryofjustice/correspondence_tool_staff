module CaseFilter
  class CaseMultiChoicesFilterBase < CaseFilterBase

    class << self

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
          "filters.#{self.class.identifier}.#{@query.send(self.class.identifier).first}", 
          default: "#{@query.send(self.class.identifier).first.humanize}"
        )
        crumb_text = I18n.t "filters.crumbs.#{self.class.identifier}",
                            count: @query.send(self.class.identifier).size,
                            first_value: summary_text,
                            remaining_values_count: @query.send(self.class.identifier).count - 1
        params = {
          self.class.identifier  => [''],
          'parent_id'          => @query.id,
        }
        our_crumbs << [crumb_text, params]
      end
      our_crumbs
    end

  end
end
