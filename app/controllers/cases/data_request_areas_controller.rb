module Cases
  class DataRequestAreasController < ApplicationController
    before_action :set_case
    before_action :set_data_request_area, only: %i[show edit update destroy]
    before_action :authorize_action
    after_action  :verify_authorized

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

      @data_request_area = service.data_request_area

      case service.result
      when :ok
        flash[:notice] = t(".success")
        redirect_to case_data_request_area_path(@case, @data_request_area)
      when :error
        render :new
      else
        raise ArgumentError, "Unknown result: #{service.result.inspect}"
      end
    end

    def update
      service = DataRequestAreaUpdateService.new(
        user: current_user,
        data_request_area: @data_request_area,
        params: update_location_params,
        )
      service.call

      case service.result
      when :ok
        flash[:notice] = t(".success")
        redirect_to case_data_request_area_path(@case, @data_request_area)
      when :unprocessed
        flash[:notice] = t(".unprocessed")
        redirect_to case_data_request_area_path(@case, @data_request_area)
      when :error
        render :show
      else
        raise ArgumentError, "Unknown result: #{service.result.inspect}"
      end
    end

    def show
      @no_location_present = @data_request_area.contact_id.nil?
    end

    def destroy
      @data_request_area.destroy!
      respond_to do |format|
        format.html { redirect_to case_path(@case), notice: "Data request was successfully destroyed." }
      end
    end

  private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request_area
      @data_request_area = DataRequestArea.find(params[:id])
    end

    def create_params
      params.require(:data_request_area).permit(:data_request_area_type)
    end

    # Only the location can be updated for a data request area
    def update_location_params
      params.require(:data_request_area).permit(:location, :contact_id)
    end

    def authorize_action
      if action_name == "show"
        authorize @case, :show?
      else
        authorize @case, :can_record_data_request?
      end
    end
  end
end
