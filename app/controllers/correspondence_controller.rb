class CorrespondenceController < ApplicationController

  before_action :set_correspondence, only: [:show, :edit, :update]

  def index
    @correspondence = Correspondence.all
  end

  def show; end

  def edit
    render :edit
  end

  def update
    if @correspondence.update(correspondence_params)
      flash[:notice] = "Correspondence updated"
      render :show
    else
      render :edit
    end
  end

  def search
    @correspondence = Correspondence.search(params[:search])
    render :index
  end

  private

  def correspondence_params
    params.require(:correspondence).permit(
      :category,
      :topic,
      :user_id
    )
  end

  def set_correspondence
    @correspondence = Correspondence.find(params[:id])
  end

end
