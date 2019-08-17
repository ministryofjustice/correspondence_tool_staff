module Cases
  class DataRequestsController < ApplicationController
    before_action :set_case, only: [:new, :create]

    def index
    end

    def show
    end

    def new
      @data_request = DataRequest.new
    end

    def create
      @data_request = DataRequest.new(
        offender_sar_case: @case,
        user: current_user,
        location: permitted_params[:location],
        data: permitted_params[:data],
      )

      if @data_request.save
        flash[:notice] = t('.success')
        redirect_to new_case_data_request_path(@case)
      else
        render :new
      end
    end

    def update
    end

    def destroy
    end


    private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def permitted_params
      params.require(:data_request).permit(:location, :data)
    end
  end
end
