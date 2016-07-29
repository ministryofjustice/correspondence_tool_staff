class CorrespondenceController < ApplicationController

  def index
    if params[:search]
      @correspondence = Correspondence.where('lower(name) LIKE ?', "%#{params[:search].downcase}%")
    else
      @correspondence = Correspondence.all
    end
  end
end
