module Cases
  class DataRequestAreasController < ApplicationController
    before_action :set_case
    before_action :set_data_request_area, only: %i[show edit update destroy]


    def new
      debugger
      @data_request_area = DataRequestArea.new
    end

    def create
      debugger
      @data_request_area = DataRequestArea.new(data_request_area_params)
      if @data_request_area.valid?
        redirect_to case_data_request_area_path(@case)
      else
        render :new_area
      end
    rescue ActionController::ParameterMissing
      redirect_to case_path(@case)
    end

    def show
      debugger
      @data_request_area = DataRequestArea.find(params[:id])
    end

    private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request_area
      @data_request_area = DataRequestAtea.find(params[:id]).decorate
    end

    def data_request_area_params
      params.require(:data_request_area).permit(:data_request_area)
    end

  end
end
