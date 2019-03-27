#rubocop:disable Metrics/ClassLength
class AssignmentsController < ApplicationController

  before_action :set_case, only: [
                  :assign_to_team,
                  :new,
                  :select_team,
                  :show_rejected,
                  :take_case_on,
                ]
  before_action :set_case_and_assignment, only: [
                  :accept,
                  :accept_or_reject,
                  :assign_to_new_team,
                  :edit,
                  :execute_assign_to_new_team,
                  :execute_reassign_user,
                  :reassign_user,
                  :unaccept,
                ]
  before_action :validate_response, only: :accept_or_reject

  def new
    authorize @case, :can_assign_case?

    @assignment = @case.assignments.new
    set_business_units
    @creating_case = flash[:creating_case]
    flash.keep :creating_case
  end

  def assign_to_team
    authorize @case, :can_assign_case?

    team = Team.find(params[:team_id])
    service = CaseAssignResponderService.new kase: @case,
                                             team: team,
                                             role: 'responding',
                                             user: current_user
    service.call
    @assignment = service.assignment
    if service.result == :ok
      flash[:notice] = flash[:creating_case] ? t('.case_created', business_unit_name: team.name) : t('.case_assigned')
      redirect_to case_path @case.id
    else
      render :new
    end
  end


  def select_team
    assignment_ids = params[:assignment_ids].split('+')
    @assignments = Assignment.find(assignment_ids)
  end

  def assign_to_new_team
    authorize @assignment, :can_assign_to_new_team?
    set_business_units
  end

  def execute_assign_to_new_team
    authorize @assignment, :can_assign_to_new_team?
    team = Team.find(params[:team_id])
    service = AssignNewTeamService.new(current_user, params)
    service.call
    if service.result == :ok
      flash[:notice] = t('.case_assigned', business_unit_name: team.name)
      redirect_to case_path @case
    else
      flash[:alert] = "Unable to assign to this team"
      redirect_to action: 'assign_to_new_team'
    end
  end

  def edit
    if @assignment
      if @assignment.accepted?
        redirect_to case_path @case, accepted_now: false
      else
        authorize @case, :can_accept_or_reject_responder_assignment?
        @correspondence_type_key = @case.type_abbreviation.downcase
        render :edit
      end
    else
      flash[:notice] = 'Case assignment does not exist.'
      redirect_to case_path @case
    end
    @case.sync_transition_tracker_for_user(current_user)
  end

  def accept_or_reject
    authorize @case, :can_accept_or_reject_responder_assignment?

    if accept?
      @assignment.accept current_user
      redirect_to case_path @assignment.case, accepted_now: true
    elsif valid_reject?
      @assignment.reject current_user, assignment_params[:reasons_for_rejection]
      flash[:notice] = "#{ @case.number} has been rejected.".html_safe
      redirect_user_to_specific_landing_page
    else
      @assignment.assign_and_validate_state(assignment_params[:state])
      render :edit
    end
  end

  #rubocop:disable Metrics/MethodLength
  def accept
    accept_service = CaseAcceptApproverAssignmentService
                       .new(user: current_user, assignment: @assignment)
    if accept_service.call
      @success = true
      @message = I18n.t('assignments.accept.success')
    else
      if accept_service.result == :not_pending
        if @assignment.user == current_user
          @success = true
          @message = I18n.t('assignments.accept.success')
        else
          @success = false
          @message = I18n.t('assignments.accept.already_accepted',
                            name: @assignment.user.full_name)
        end
      else
        raise RuntimeError.new(
                "Unknown error when accepting approver assignment: " +
                accept_service.result.to_s
              )
      end
    end
    respond_to do |format|
      format.js { render 'assignments/accept.js.erb' }
      format.html do
        if @success
          flash[:notice] = "#{ @message}. #{ get_undo_link }".html_safe
        elsif @success == false
          flash[:error] = @message
        end
        redirect_to case_path(@case)
      end
    end
  end
  #rubocop:enable Metrics/MethodLength

  def take_case_on
    service = CaseFlagForClearanceService.new(user: current_user,
                                              kase: @case,
                                              team: current_user.approving_team)
    result = service.call
    if result == :ok
      @success = true
      @message = I18n.t('assignments.take_case_on.success')
    elsif result == :already_flagged
      @success = false
      @message = I18n.t('assignments.take_case_on.already_accepted', name: service.other_user.full_name)
    else
      raise RuntimeError.new("Unknown error when accepting approver assignment: " + result.to_s)
    end

    respond_to do |format|
      format.js { render 'assignments/accept.js.erb' }
      format.html do
        if @success
          flash[:notice] = "#{ @message}. #{ get_undo_link }".html_safe
        elsif @success == false
          flash[:error] = @message
        end
        redirect_to case_path(@case)
      end
    end
  end

  def unaccept
    unaccept_service = CaseUnacceptApproverAssignmentService
                         .new(assignment: @assignment)
    unaccept_service.call

    respond_to do |format|
      format.js { render 'assignments/unaccept.js.erb' }
      format.html { redirect_to case_path(@case) }
    end
  end

  def reassign_user
    authorize @case, :assignments_reassign_user?
    @team_users = set_team_users.decorate
  end

  def execute_reassign_user
    authorize @case, :assignments_execute_reassign_user?

    target_user = User.find(reassign_user_params[:user_id])
    urs = UserReassignmentService
              .new(target_user: target_user,
                   acting_user: current_user,
                   assignment: @assignment)

    if urs.call == :ok
      flash[:notice] = "Case re-assigned to #{@assignment.user.full_name}"
      redirect_to case_path(@case)
    end

  end

  private

  def set_business_units
    correspondence_type = @case.correspondence_type_for_business_unit_assignment
    if params[:business_group_id].present?
      @business_units = BusinessGroup
                          .includes(:directorates, :business_units => :areas)
                          .find(params[:business_group_id])
                          .business_units
                          .responding_for_correspondence_type(correspondence_type)
                          .order(:name)
    elsif params[:show_all].present? && params[:show_all]
      @business_units = BusinessUnit
                          .includes(:areas)
                          .responding_for_correspondence_type(correspondence_type)
                          .order(:name)
    end
  end

  def assignment_params
    if params[:assignment]
      params.require(:assignment).permit(
        :state,
        :team_id,
        :reasons_for_rejection
      )
    else
      HashWithIndifferentAccess.new
    end
  end

  def get_assign_team_params
    { team_id: params[:team_id],
      case_id: params[:case_id],
      role: 'responding'}
  end

  def reassign_user_params
    params.require(:assignment).permit(
      :user_id
    )

  end

  def set_case_and_assignment
    if Case::Base.exists?(id: params[:case_id])
      set_case
    end
    if Assignment.exists?(id: params[:id])
      @assignment = @case.assignments.find(params[:id])
    end
  end

  def set_case
    @case = Case::Base
              .includes(:transitions => [:target_team, :acting_team, :acting_user])
              .find(params[:case_id])
              .decorate
    @case_transitions = @case.transitions.decorate
  end

  def set_team_users
    @assignment.team.users.order(:full_name)
  end

  def validate_response
    if assignment_params[:state].nil?
      @assignment.errors.add(:state, :blank)
    end
  end

  def accept?
    assignment_params[:state] == 'accepted'
  end

  def valid_reject?
    assignment_params[:state] == 'rejected' &&
      assignment_params[:reasons_for_rejection].match(/\S/)
  end

  def get_undo_link
    unlink_path = unaccept_case_assignment_path(@case, @case.approver_assignments
                                                           .with_teams(current_user.teams)
                                                           .first)
    view_context.link_to "Undo",
                         unlink_path,
                         { method: :patch, class: "undo-take-on-link"}
  end

  def redirect_user_to_specific_landing_page
    case @case.type_abbreviation
    when 'FOI', 'OVERTURNED_FOI' then redirect_to case_path(@case)
    when 'SAR', 'OVERTURNED_SAR' then redirect_to responder_root_path
    when 'ICO' then
      if @case.original_case_type === 'SAR'
        redirect_to responder_root_path
      else
        redirect_to case_path(@case)
      end
    else raise 'Unknown case type'
    end
  end
end
#rubocop:enable Metrics/ClassLength
