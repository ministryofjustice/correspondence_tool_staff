class AssignmentsController < ApplicationController

  before_action :set_case, only: [:new, :create, :edit, :accept_or_reject, :show_rejected]
  before_action :set_assignment, only: [:edit, :accept_or_reject]
  before_action :validate_response, only: :accept_or_reject

  def new
    @assignment = @case.assignments.new
  end

  def create
    @assignment = @case.create_assignment(
      assignment_params.merge(assignment_type: 'drafter', assigner: current_user)
    )

    if @assignment.valid?
      flash[:notice] = t('.case_created')
      redirect_to cases_path
    else
      render :new
    end
  end

  def edit    
    if @assignment
      if already_accepted?
        redirect_to case_path @case, accepted_now: false
      else
        authorize @case, :can_accept_or_reject_case?
        render :edit
      end
    elsif @assignment.nil? && already_rejected?
      redirect_to case_assignments_show_rejected_path @case, rejected_now: false
    end
  end

  def accept_or_reject
    authorize @case, :can_accept_or_reject_case?

    if accept?
      @assignment.accept
      redirect_to case_path @assignment.case, accepted_now: true
    elsif valid_reject?
      @assignment.reject assignment_params[:reasons_for_rejection]
      redirect_to case_assignments_show_rejected_path @case, rejected_now: true
    else
      @assignment.assign_and_validate_state(assignment_params[:state])
      render :edit
    end
  end

  def show_rejected
    @rejected_now = params[:rejected_now]
    render
  end

  private

  def assignment_params
    params.require(:assignment).permit(
      :state,
      :assignee_id,
      :reasons_for_rejection
    )
  end

  def set_assignment
    if Assignment.exists?(id: params[:id])
      @assignment = Assignment.find(params[:id])
    end
  end

  def already_rejected?
    @case.transitions.any? do |transition|
      transition.assignment_id == params[:id].to_i && transition.event =='reject_responder_assignment'
    end
  end

  def already_accepted?
    Assignment.where(id: params[:id], state: 'accepted').present?
  end

  def set_case
    @case = Case.find(params[:case_id])
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
