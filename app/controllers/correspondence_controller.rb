class CorrespondenceController < ApplicationController

  before_action :set_correspondence, only: [:show, :edit, :update, :assign]

  def index
    @correspondence = Correspondence.all
  end

  def show; end

  def edit
    render :edit
  end

  def update
    if @correspondence.update(edit_correspondence_params)
      flash[:notice] = "Correspondence updated"
      render :show
    else
      render :edit
    end
  end

  def assign
    if @correspondence.update(assign_correspondence_params) && @correspondence.drafter
      flash[:notice] = "Correspondence assigned to #{@correspondence.drafter.email}"
    end
    render :show
  end

  def search
    @correspondence = Correspondence.search(params[:search])
    render :index
  end

  private

  def edit_correspondence_params
    params.require(:correspondence).permit(
      :category,
      :topic
    )
  end

  def assign_correspondence_params
    params.require(:correspondence).permit(
      :user_id
    )
  end

  def set_correspondence
    @correspondence = Correspondence.find(params[:id])
  end

end
