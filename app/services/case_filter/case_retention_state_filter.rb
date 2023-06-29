module CaseFilter
  class CaseRetentionStateFilter < CaseMultiChoicesFilterBase
    class << self
      def identifier
        "filter_retention_state"
      end

      def filter_attributes
        [:filter_retention_state]
      end
    end

    def available_choices
      { filter_retention_state: retention_states }
    end

    def call
      @records.where(
        retention_schedule: { state: @query.filter_retention_state },
      )
    end

  private

    def retention_states
      RetentionSchedule.states_map.except(*excluded_states).stringify_keys
    end

    # No need to show checkbox for state `anonymised`, as these cases
    # will not show in the tab where this filter is applied.
    def excluded_states
      [
        RetentionSchedule::STATE_ANONYMISED,
      ]
    end
  end
end
