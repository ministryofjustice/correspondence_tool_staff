module Cases
  class DataRequestAreasController < ApplicationController
    before_action :set_case
    before_action :set_data_request_area, only: %i[show edit update destroy]

    def new
      @data_request_area = DataRequestArea.new
    end

    def create
      service = DataRequestAreaCreateService.new(
        kase: @case,
        user: current_user,
        data_request_area_params: create_params,
        )
      service.call

      case service.result
      when :ok
        flash[:notice] = t(".success")
        redirect_to case_path(@case)
      when :error
        @case = service.case
        @data_request_area = service.data_request_area
        render :new
      else
        raise ArgumentError, "Unknown result: #{service.result.inspect}"
      end
    end

  private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request_area
      @data_request_area = DataRequestAtea.find(params[:id]).decorate
    end

    def create_params
      params.require(:data_request_area).permit(:data_request_area_type)
    end
  end
end
