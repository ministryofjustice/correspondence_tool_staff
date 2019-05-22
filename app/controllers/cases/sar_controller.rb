module Cases
  class SarController < ApplicationController
    include NewCase
    include CreateCase

    def new
      new_case_for(CorrespondenceType.sar)
      render 'cases/new'
    end

    def create
      create_case_for_type(CorrespondenceType.sar, 'sar')
    end
  end
end
