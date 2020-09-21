module CaseFilter
  class ExternalDeadlineFilter < CaseFilterBase

    def self.template_name
      return 'final_deadline'
    end

    def self.filter_attributes
      [:external_deadline_from, :external_deadline_to]
    end

    def applied?
      @query.external_deadline_from.present? &&
        @query.external_deadline_to.present?
    end

    def presented?
      @query.external_deadline_from && @query.external_deadline_to
    end 

    def available_choices
      {
        today: { day: Date.today.strftime("%d"), month: Date.today.strftime("%m"), year: Date.today.strftime("%Y") }.to_json,
        three_days: { day: 3.business_days.from_now.strftime("%d"), month: 3.business_days.from_now.strftime("%m"), year: 3.business_days.from_now.strftime("%Y") }.to_json,
        ten_days: { day: 10.business_days.from_now.strftime("%d"), month: 10.business_days.from_now.strftime("%m"), year: 10.business_days.from_now.strftime("%Y") }.to_json
      }
    end

    def call
      if presented?
        deadline_is_within_period(@query.external_deadline_from,
                                  @query.external_deadline_to)
      else
        @results
      end
    end

    def crumbs
      if presented?
        crumb_text = I18n.t 'filters.crumbs.external_deadline',
                            from_date: I18n.l(@query.external_deadline_from),
                            to_date: I18n.l(@query.external_deadline_to)

        params = {
          'external_deadline_from' => '',
          'external_deadline_to'   => '',
          'parent_id'              => @query.id
        }
        [[crumb_text, params]]
      else
        []
      end
    end

    private

    def deadline_is_within_period(from_date, to_date)
      @results.deadline_within(from_date, to_date)
    end
  end
end
