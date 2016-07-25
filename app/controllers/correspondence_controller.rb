class CorrespondenceController < ApplicationController

  def index
    @correspondence = Correspondence.all
  end

end
