module CaseFilter
  class TimelinessFilter < CaseMultiChoicesFilterBase

    def self.filter_attributes
      [:filter_timeliness]
    end

    def available_choices
      {
        :filter_timeliness => {
          'in_time' => I18n.t('filters.timeliness.in_time'),
          'late'    => I18n.t('filters.timeliness.late'),
        }
      }
      
    end

    def call
      filter_timeliness(@records)
    end

    def crumbs
      if applied?
        timeliness_text = I18n.t(
          "filters.timeliness.#{@query.filter_timeliness.first}"
        )
        crumb_text = I18n.t "filters.crumbs.timeliness",
                            count: @query.filter_timeliness.size,
                            first_value: timeliness_text,
                            remaining_values_count: @query.filter_timeliness.count - 1
        params = {
          'filter_timeliness' => [''],
          'parent_id'         => @query.id
        }
        [[crumb_text, params]]
      else
        []
      end
    end

    private

    def filter_in_time?
      'in_time'.in? @query.filter_timeliness
    end

    def filter_late?
      'late'.in? @query.filter_timeliness
    end

    def filter_timeliness(records)
      if filter_in_time? && !filter_late?
        records.in_time
      elsif !filter_in_time? && filter_late?
        records.late
      else
        records
      end
    end
  end
end
