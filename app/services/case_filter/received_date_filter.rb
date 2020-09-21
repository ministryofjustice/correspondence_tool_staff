module CaseFilter
  class ReceivedDateFilter < CaseFilterBase

    def self.template_name
      'date_range'
    end
    
    def self.date_field_name
      'received_date'
    end

    def self.date_from_field
      :received_date_from
    end

    def self.date_to_field
      :received_date_to
    end

    def self.filter_attributes
      [date_from_field, date_to_field]
    end

    def self.process_params!(params)
      process_date_param(params, 'received_date_from')
      process_date_param(params, 'received_date_to')
    end

    def applied?
      @query.send(self.class.date_from_field.to_s).present? &&
        @query.send(self.class.date_to_field.to_s).present?
    end

    def presented?
      @query.send(self.class.date_from_field.to_s) && @query.send(self.class.date_to_field.to_s)
    end 

    def available_choices
      {
        up_to_nine_month: {
          name: 'Up to Nine month',
          from: { day: 9.months.ago.strftime("%d"), month: 9.months.ago.strftime("%m"), year: 9.months.ago.strftime("%Y") }.to_json,
          to: { day: Date.today.strftime("%d"), month: Date.today.strftime("%m"), year: Date.today.strftime("%Y") }.to_json
        },
        nine_to_two_year: {
          name: 'Nine month to 2 year',
          from: { day: 24.months.ago.strftime("%d"), month: 24.months.ago.strftime("%m"), year: 24.months.ago.strftime("%Y") }.to_json,
          to: { day: 9.months.ago.strftime("%d"), month: 9.months.ago.strftime("%m"), year: 9.months.ago.strftime("%Y") }.to_json,
        },
        two_to_eight_year: {
          name: '2 to 8 year',
          from: { day: 96.months.ago.strftime("%d"), month: 96.months.ago.strftime("%m"), year: 96.months.ago.strftime("%Y") }.to_json,
          to: { day: 24.months.ago.strftime("%d"), month: 24.months.ago.strftime("%m"), year: 9.months.ago.strftime("%Y") }.to_json,
        }
      }

    end

    def call
      if presented?
        @records.where(received_date: @query.received_date_from..@query.received_date_to)
      else
        @records
      end
    end

    def crumbs
      if presented?
        crumb_text = I18n.t 'filters.crumbs.received_date',
                            from_date: I18n.l(@query.send(self.class.date_from_field.to_s)),
                            to_date: I18n.l(@query.send(self.class.date_to_field.to_s))

        params = {
          self.class.date_from_field.to_s => '',
          self.class.date_to_field.to_s   => '',
          'parent_id'              => @query.id
        }
        [[crumb_text, params]]
      else
        []
      end
    end
  end
end
