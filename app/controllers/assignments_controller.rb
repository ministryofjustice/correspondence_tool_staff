class AssignmentsController < ApplicationController

  before_action :set_case, only: [
                  :accept,
                  :accept_or_reject,
                  :assign_to_team,
                  :edit,
                  :execute_reassign_user,
                  :new,
                  :reassign_user,
                  :show_rejected,
                  :take_case_on,
                  :unaccept,
                ]
  before_action :set_assignment, only: [
                  :accept,
                  :accept_or_reject,
                  :edit,
                  :execute_reassign_user,
                  :reassign_user,
                  :unaccept,
                ]
  before_action :validate_response, only: :accept_or_reject

  def new
    authorize @case, :can_assign_case?
    @assignment = @case.assignments.new
    if params[:business_group_id].present?
      @business_units = BusinessGroup.find(params[:business_group_id])
                            .business_units.responding.order(:name)
    elsif params[:show_all].present? && params[:show_all]
      @business_units = BusinessUnit.responding.order(:name)
    end

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
      flash[:notice] = flash[:creating_case] ? t('.case_created') : t('.case_assigned')
      redirect_to case_path @case.id
    else
      render :new
    end

  end

  def edit
    if @assignment
      if @assignment.accepted?
        redirect_to case_path @case, accepted_now: false
      elsif @assignment.rejected?
        redirect_to case_assignments_show_rejected_path @case, rejected_now: false
      else
        authorize @case, :can_accept_or_reject_responder_assignment?
        render :edit
      end
    else
      flash[:notice] = 'Case assignment does not exist.'
      redirect_to case_path @case
    end
  end

  def accept_or_reject
    authorize @case, :can_accept_or_reject_responder_assignment?

    if accept?
      @assignment.accept current_user
      redirect_to case_path @assignment.case, accepted_now: true
    elsif valid_reject?
      @assignment.reject current_user, assignment_params[:reasons_for_rejection]
      redirect_to case_assignments_show_rejected_path @case, rejected_now: true
    else
      @assignment.assign_and_validate_state(assignment_params[:state])
      render :edit
    end
  end

  def accept
    accept_service = CaseAcceptApproverAssignmentService
                       .new(user: current_user, assignment: @assignment)
    if accept_service.call
      @success = true
      @message = t('.success')
    else
      if accept_service.result == :not_pending
        if @assignment.user == current_user
          @success = true
          @message = t('.success')
        else
          @success = false
          @message = t('.already_accepted', name: @assignment.user.full_name)
        end
      else
        raise RuntimeError.new(
                "Unknown error when accepting approver assignment: " +
                accept_service.result.to_s
              )
      end
    end
  end

  def take_case_on
    service = CaseFlagForClearanceService.new(user: current_user,
                                              kase: @case,
                                              team: current_user.approving_team)
    result = service.call
    if result == :ok
      @success = true
      @message = t('.success')
    elsif result == :already_flagged
      @success = false
      @message = t('.already_accepted', name: service.other_user.full_name)
    else
      raise RuntimeError.new("Unknown error when accepting approver assignment: " + result.to_s)
    end

    render 'assignments/accept.js.erb'
  end

  def unaccept
    unaccept_service = CaseUnacceptApproverAssignmentService
                         .new(assignment: @assignment)
    unaccept_service.call
  end

  def show_rejected
    @rejected_now = params[:rejected_now]
    render
  end

  def reassign_user
    authorize @case, :assignments_reassign_user?
    @team_users = set_team_users
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

  def set_assignment
    if Assignment.exists?(id: params[:id])
      @assignment = Assignment.find(params[:id])
    end
  end

  def set_case
    @case = Case.find(params[:case_id])
    @case_transitions = @case.transitions.decorate
  end

  def set_team_users
    if current_user.responder?
      @case.responding_team_users.order(:full_name)
    elsif current_user.approver?
      current_user.approving_team.users.order(:full_name)
    end
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
end
