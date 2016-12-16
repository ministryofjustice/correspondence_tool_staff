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
      redirect_to cases_path
    else
      render :new
    end
  end

  def edit; end

  def update
    if @assignment.update(assignment_params)
      redirect_to 'case#show', params: { id: params[:case_id] }
    else
      render :edit
    end
  end

  private

  def assignment_params
    params.require(:assignment).permit(
      :state,
      :assignee_id
    )
  end

  def set_assignment
    @assignment = Assignment.find(params[:id])
  end

  def set_case
    @case = Case.find(params[:case_id])
  end

end
