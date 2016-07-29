class CorrespondenceController < ApplicationController

  def index
    @correspondence = Correspondence.all
  end

  def search
    @correspondence = Correspondence.search(params[:search])
    render :index
  end
end
