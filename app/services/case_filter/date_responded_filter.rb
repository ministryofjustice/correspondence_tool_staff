module CaseFilter
  class DateRespondedFilter < CaseFilterBase

    def self.template_name
      return 'date_range'
    end

    def self.filter_attributes
      [:date_responded_from, :date_responded_to]
    end

    def applied?
      @query.date_responded_from.present? &&
        @query.date_responded_to.present?
    end

    def presented?
      @query.date_responded_from && @query.date_responded_to
    end 

    def available_choices
      {
        today: { day: Date.today.strftime("%d"), month: Date.today.strftime("%m"), year: Date.today.strftime("%Y") }.to_json,
        three_months: { day: 3.months.from_now.strftime("%d"), month: 3.months.from_now.strftime("%m"), year: 3.months.from_now.strftime("%Y") }.to_json,
        six_months: { day: 6.months.from_now.strftime("%d"), month: 6.months.from_now.strftime("%m"), year: 6.months.from_now.strftime("%Y") }.to_json
      }
    end

    def call
      if presented?
        @results..where(date_responded: @query.date_responded_from..@query.date_responded_to)
      else
        @results
      end
    end

    def crumbs
      if presented?
        crumb_text = I18n.t 'filters.crumbs.date_responded',
                            from_date: I18n.l(@query.date_responded_from),
                            to_date: I18n.l(@query.date_responded_to)

        params = {
          'date_responded_from' => '',
          'date_responded_to'   => '',
          'parent_id'              => @query.id
        }
        [[crumb_text, params]]
      else
        []
      end
    end
  end
end
