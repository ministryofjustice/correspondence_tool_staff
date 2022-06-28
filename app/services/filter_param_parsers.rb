module FilterParamParsers
  extend ActiveSupport::Concern

  class_methods do
    def process_array_param(params, name)
      if params.key?(name)
        params[name] = params[name].compact_blank.sort
      end
    end

    def process_date_param(params, name)
      year_param  = "#{name}_yyyy"
      month_param = "#{name}_mm"
      day_param   = "#{name}_dd"

      date_params_present = params[year_param].present? &&
                            params[month_param].present? &&
                            params[day_param].present?
      if date_params_present
        params[name] = Date.new(params[year_param].to_i,
                                params[month_param].to_i,
                                params[day_param].to_i)
      elsif params.key?(name) && params[name] == ''
        params[name] = nil
      end
    end

    def process_ids_param(params, name)
      if params.key?(name)
        params[name] = params[name]
                         .grep_v('')
                         .map(&:to_i)
                         .sort
      end
    end
  end
end
