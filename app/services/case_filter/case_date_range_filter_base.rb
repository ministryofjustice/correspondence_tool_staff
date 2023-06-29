module CaseFilter
  class CaseDateRangeFilterBase < CaseFilterBase
    def self.date_field_name
      raise "#call should be defined in sub-class of CaseDateRangeFilterBase"
    end

    def self.identifier
      "filter_#{date_field_name}"
    end

    def self.template_name
      "date_range"
    end

    def self.date_from_field
      "#{date_field_name}_from".to_sym
    end

    def self.date_to_field
      "#{date_field_name}_to".to_sym
    end

    def self.set_params(params)
      params.permit(
        "#{date_field_name}_from".to_sym,
        "#{date_field_name}_from_dd".to_sym,
        "#{date_field_name}_from_mm".to_sym,
        "#{date_field_name}_from_yyyy".to_sym,
        "#{date_field_name}_to".to_sym,
        "#{date_field_name}_to_dd".to_sym,
        "#{date_field_name}_to_mm".to_sym,
        "#{date_field_name}_to_yyyy".to_sym,
      )
    end

    def self.filter_fields(filter_fields)
      filter_fields["#{date_field_name}_from".to_sym] = :date
      filter_fields["#{date_field_name}_to".to_sym] = :date
    end

    def self.date_fields
      [date_from_field, date_to_field]
    end

    def self.filter_attributes
      [date_from_field, date_to_field]
    end

    def self.process_params!(params)
      filter_attributes.each do |filter_attribute|
        process_date_param(params, filter_attribute.to_s)
      end
    end

    def applied?
      @query.send(self.class.date_from_field.to_s).present? &&
        @query.send(self.class.date_to_field.to_s).present?
    end

    def presented?
      @query.send(self.class.date_from_field.to_s) && @query.send(self.class.date_to_field.to_s)
    end

    def available_choices
      []
    end

    def call
      if presented?
        from_date = @query.send(self.class.date_from_field)
        to_date = @query.send(self.class.date_to_field)
        date_field_name = ActiveRecord::Base.sanitize_sql(self.class.date_field_name)
        sql = "#{date_field_name} BETWEEN ? AND ?"
        @records.where([sql, from_date, to_date])
      else
        @records
      end
    end

    def crumbs
      if presented?
        crumb_text = I18n.t "filters.crumbs.#{self.class.date_field_name}",
                            from_date: I18n.l(@query.send(self.class.date_from_field.to_s)),
                            to_date: I18n.l(@query.send(self.class.date_to_field.to_s))

        params = {
          self.class.date_from_field.to_s => "",
          self.class.date_to_field.to_s => "",
          "parent_id" => @query.id,
        }
        [[crumb_text, params]]
      else
        []
      end
    end
  end
end
