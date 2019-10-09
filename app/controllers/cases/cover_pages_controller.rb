module Cases
  class CoverPagesController < ApplicationController
    before_filter :set_case, only: [:show]

    def show
    end

    private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end
  end
end
