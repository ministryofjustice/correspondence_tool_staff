class CaseRequireFurtherActionService
  attr_reader :result, :error_message

  def initialize(user, kase, update_parameters)
    @user = user
    @kase = kase
    @update_parameters = update_parameters
    @result = :incomplete
    @error_message = nil

    @trigger_event_name = nil
    @target_team = nil
  end


  def call
    begin
      ActiveRecord::Base.transaction do
        update_attributes
        if validate_dates?
          save_attributes
          trigger_flow_action
          @result = :ok
        else
          @result = :error
        end
      end
    rescue ConfigurableStateMachine::InvalidEventError => err
      @kase.errors.add(:external_deadline, err.message)
      @result = :error
    rescue StandardError => error
      @kase.errors.add(:external_deadline, error.message)
      @error_message = error.message
      @result = :error
    end
  end 
    
  private 

  def update_attributes
    update_deadline_attributes
    @kase.assign_attributes(@update_parameters)
  end

  def update_deadline_attributes
    if requie_update_deadlines?
      # only store the original deadlines not previous deadline as the case can be reverted multiple times.
      if (@kase.original_internal_deadline.nil? &&  @kase.original_external_deadline.nil?)
        @kase.original_internal_deadline = @kase.internal_deadline
        @kase.original_external_deadline = @kase.external_deadline
      end
    end
  end

  def save_attributes
    add_ico_further_files
    @kase.save!
  end

  def requie_update_deadlines?
    @update_parameters[:external_deadline_dd].present?
  end

  def validate_dates?
    if requie_update_deadlines?
      # Check whether the deadline dates are in the past, this validation rule is not 
      # suitable on the data model level as users may changed them after initial action
      if Date.parse(@kase.internal_deadline) <= Date.today
        @kase.errors.add(
          :internal_deadline,
          I18n.t('activerecord.errors.models.case/ico.attributes.internal_deadline.past')
        )
      end 

      if Date.parse(@kase.external_deadline) <= Date.today
        @kase.errors.add(
          :external_deadline,
          I18n.t('activerecord.errors.models.case/ico.attributes.external_deadline.past')
        )
      end 
    end
    !@kase.errors.present?
  end

  def trigger_flow_action
    team = @user.case_team_for_event(@kase, 'record_further_action')
    # @kase.state_machine.record_further_action!(
    #   acting_user: @user, 
    #   acting_team: team
    # )
    # @kase.state_machine.edit_case!(acting_user: @user, acting_team: team)
    # @kase.state_machine.require_further_action!(
    #   acting_user: @user, 
    #   acting_team: team,
    # )
    determine_event_name
    @kase.state_machine.send(@trigger_event_name + '!', {
      acting_user: @user, 
      acting_team: team,
      target_team: @target_team, 
      message: I18n.t("event.case/ico.#{@trigger_event_name}_message", team: @target_team.name)   
    })
  end
  
  def add_ico_further_files
    if @update_parameters[:uploaded_ico_further_request_files].present?
      uploader = S3Uploader.new(@kase, @user)
      uploader.process_files(@update_parameters[:uploaded_ico_further_request_files], :further_request)
    end
  end

  def determine_event_name
    if @kase.responding_team.active?
      check_responder_state
    else 
      @kase.clear_responding_assignment
      @event_message = I18n.t('notices.case/ico.case_required_further_action_reassign')
    end
  end

  def check_responder_state
    @target_team = @kase.responding_team
    if !@kase.responder.deactivated? && @kase.responding_team.users.include?(@kase.responder)
      @trigger_event_name = 'require_further_action'
    else
      @kase.reset_responding_assignment_flag
      @trigger_event_name = 'require_further_action_to_responder_team'
    end
  end 


end

