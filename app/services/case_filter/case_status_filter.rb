module CaseFilter
  class CaseStatusFilter < CaseFilterBase

    def self.filter_attributes
      [:filter_status]
    end

    # def applied?
    #   @query.filter_status.present?
    # end

    def get_available_choices
      {
        :filter_status => 
          {'open'   => I18n.t('filters.statuses.open'),
          'closed' => I18n.t('filters.statuses.closed')}
      }
    end

    def call
      filter_status(@records)
    end

    def crumbs
      if applied?
        status_text = I18n.t(
          "filters.statuses.#{@query.filter_status.first}"
        )
        crumb_text = I18n.t "filters.crumbs.status",
                            count: @query.filter_status.size,
                            first_value: status_text,
                            remaining_values_count: @query.filter_status.count - 1
        params = {
          'filter_status' => [''],
          'parent_id'     => @query.id
        }
        [[crumb_text, params]]
      else
        []
      end
    end

    private

    def filter_open?
      'open'.in? @query.filter_status
    end

    def filter_closed?
      'closed'.in? @query.filter_status
    end

    def filter_status(records)
      if filter_open? && !filter_closed?
        records.opened
      elsif !filter_open? && filter_closed?
        records.closed
      else
        records
      end
    end
  end
end
