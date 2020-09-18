class OpenCaseStatusFilter
  include FilterParamParsers

  attr_reader :available_choices

  # def self.available_offender_sar_case_statuses
  #   {
  #     'data_to_be_requested' => I18n.t('filters.offender_sar_case_statuses.data_to_be_requested'),
  #     'waiting_for_data'     => I18n.t('filters.offender_sar_case_statuses.waiting_for_data'),
  #     'ready_for_vetting'    => I18n.t('filters.offender_sar_case_statuses.ready_for_vetting'),
  #     'vetting_in_progress'  => I18n.t('filters.offender_sar_case_statuses.vetting_in_progress'),
  #     'ready_to_copy'        => I18n.t('filters.offender_sar_case_statuses.ready_to_copy'),
  #     'ready_to_dispatch'    => I18n.t('filters.offender_sar_case_statuses.ready_to_dispatch'),
  #     'closed'               => I18n.t('filters.offender_sar_case_statuses.closed'),
  #     'destroyed'            => I18n.t('filters.offender_sar_case_statuses.destroyed'),
  #   }
  # end


  def self.filter_attributes
    # [:filter_open_case_status, :filter_offender_sar_case_status]
    [:filter_open_case_status]
  end

  def self.process_params!(params)
    process_array_param(params, :filter_open_case_status)
  end

  def self.template_name
    return 'filter_multiple_choices'
  end

  def is_available?
    true
  end

  def initialize(query, user, records)
    @query = query
    @records = records
    @user = user

    @available_choices = get_available_choices
  end

  def applied?
    @query.filter_open_case_status.present?
  end

  def call
    if @query.filter_open_case_status.any?
      @records = @records.where(current_state: @query.filter_open_case_status)
    end
    @records
  end

  def crumbs
    if applied?
      status_text = I18n.t(
        "filters.open_case_statuses.#{@query.filter_open_case_status.first}"
      )
      crumb_text = I18n.t "filters.crumbs.open_case_status",
                          count: @query.filter_open_case_status.size,
                          first_value: status_text,
                          remaining_values_count: @query.filter_open_case_status.count - 1
      params = {
        'filter_open_case_status' => [''],
        'parent_id'               => @query.id
      }
      [[crumb_text, params]]
    else
      []
    end
  end

  private 

  def get_available_choices
    collected_states = []
    user.permitted_correspondence_types.each do | correspondence_type |
      collected_states.push(*correspondence_type.name.constantize.permitted_states)
    end 
    state_choices = {}
    (collected_states.uniq - ConfigurableStateMachine::Machine.states_for_closed_cases).each do | state |
      state_choices[state] = I18n.t("filters.open_case_statuses.#{state}")
    end
    state_choices
  end

end

