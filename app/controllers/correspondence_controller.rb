class CorrespondenceController < ApplicationController

  def index
    @correspondence = Correspondence.all
  end

  def edit
    @correspondence = Correspondence.find(params[:id])
    render :edit
  end

  def search
    @correspondence = Correspondence.search(params[:search])
    render :index
  end
end
