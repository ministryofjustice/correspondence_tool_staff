module CaseFilter
  class CaseStatusFilter < CaseMultiChoicesFilterBase

    def self.identifier
        'filter_status'
    end

    def self.filter_attributes
      [:filter_status]
    end

    def available_choices
      {
        filter_status: {
          'open'   => I18n.t('filters.filter_status.open'),
          'closed' => I18n.t('filters.filter_status.closed')
        }
      }
    end

    def call
      filter_status(@records)
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
