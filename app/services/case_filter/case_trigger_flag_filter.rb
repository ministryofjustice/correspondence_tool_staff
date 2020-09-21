module CaseFilter
  class CaseTriggerFlagFilter < CaseFilterBase

    class << self
      def filter_attributes
        [:filter_sensitivity]
      end

      def self.set_params(params)
        params.permit(filter_sensitivity: [])
      end  
    end

    def get_available_choices
      {
        :filter_sensitivity => {
          'non-trigger' => I18n.t('filters.sensitivities.non-trigger'),
          'trigger'     => I18n.t('filters.sensitivities.trigger')
        }
      }
    end

    # def applied?
    #   @query.filter_case_type.present? || @query.filter_sensitivity.present?
    # end

    def is_available?
      @user.permitted_correspondence_types.any? { | c_type | ['FOI'].include? c_type.abbreviation }
    end

    def call
      records = @records
      records = filter_sensitivity(records)
      records
    end

    def crumbs
      our_crumbs = []
      if applied?
        sensitivity_text = I18n.t(
          "filters.sensitivities.#{@query.filter_sensitivity.first}"
        )
        crumb_text = I18n.t "filters.crumbs.sensitivity",
                            count: @query.filter_sensitivity.size,
                            first_value: sensitivity_text,
                            remaining_values_count: @query.filter_sensitivity.count - 1
        params = {
          'filter_sensitivity' => [''],
          'parent_id'          => @query.id,
        }
        our_crumbs << [crumb_text, params]
      end
      our_crumbs
    end

    private

    def filter_trigger?
      'trigger'.in? @query.filter_sensitivity
    end

    def filter_non_trigger?
      'non-trigger'.in? @query.filter_sensitivity
    end

    def filter_sensitivity(records)
      if filter_trigger? && !filter_non_trigger?
        records.trigger
      elsif !filter_trigger? && filter_non_trigger?
        records.non_trigger
      else
        records
      end
    end
  end
end
