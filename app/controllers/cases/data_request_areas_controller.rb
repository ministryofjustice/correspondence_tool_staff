module Cases
  class DataRequestAreasController < ApplicationController
    before_action :set_case
    before_action :set_data_request_area, only: %i[show update destroy]
    before_action :authorize_action

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
      @data_request_area.destroy! unless @data_request_area.data_requests.exists?
      respond_to do |format|
        format.html { redirect_to case_path(@case), notice: "Data request was successfully destroyed." }
      end
    end

  private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request_area
      @data_request_area = @case.data_request_areas.find(params[:id])
    end

    def create_params
      params.require(:data_request_area).permit(:data_request_area_type)
    end

    def update_location_params
      params.require(:data_request_area).permit(:location, :contact_id)
    end

    def authorize_action
      case action_name
      when "show"
        authorize @case, :show?
      when "update"
        authorize @case, :edit?
      else
        authorize @case, :can_record_data_request?
      end
    end
  end
end
