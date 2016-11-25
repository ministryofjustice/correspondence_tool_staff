class AssignmentsController < ApplicationController

  before_action :set_assignment, only: [:edit, :update]
  before_action :set_correspondence, only: [:new, :create, :edit]

  def new
    @assignment = @correspondence.assignments.new
  end

  def create
    @assignment = @correspondence.assignments.new(
      assignment_params.merge(assignment_type: 'drafter', assigner: current_user)
    )

    if @assignment.save!
      redirect_to correspondence_index_path
    else
      render :new
    end
  end

  def edit; end

  def update
    if @assignment.update(assignment_params)
      redirect_to 'correspondence#show', params: { id: params[:correspondence_id] }
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

  def set_correspondence
    @correspondence = Correspondence.find(params[:correspondence_id])
  end

end
