class AssignmentsController < ApplicationController

  before_action :set_assignment, only: [:edit, :update]
  before_action :set_case, only: [:new, :create, :edit]

  def new
    @assignment = @case.assignments.new
  end

  def create
    @assignment = @case.assignments.new(
      assignment_params.merge(assignment_type: 'drafter', assigner: current_user)
    )

    if @assignment.save!
      flash[:notice] = t('.case_created')
      redirect_to cases_path
    else
      render :new
    end
  end

  def edit; end

  def update
    new_state = (assignment_params[:state] + '!').to_sym

    if @assignment.send(new_state)
      redirect_to case_path @assignment.case
    else
      render :edit
    end
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
    @assignment = Assignment.find(params[:id])
  end

  def set_case
    @case = Case.find(params[:case_id])
  end

end
