module Cases
  class PitExtensionController < ApplicationController
    include SetupCase

    before_action :set_case, only: [:new, :create, :destroy]

    # Was extend_for_pit
    def new
      authorize @case

      @case = CaseExtendForPITDecorator.decorate @case
    end

    # Was execute_extend_for_pit
    def create
      authorize @case, :extend_for_pit?

      pit_params = params[:case]
      extension_deadline = Date.new(
        pit_params[:extension_deadline_yyyy].to_i,
        pit_params[:extension_deadline_mm].to_i,
        pit_params[:extension_deadline_dd].to_i
      ) rescue nil
      service = CaseExtendForPITService.new current_user,
                                            @case,
                                            extension_deadline,
                                            pit_params[:reason_for_extending]
      result = service.call

      if result == :ok
        flash[:notice] = 'Case extended for Public Interest Test (PIT)'
        redirect_to case_path(@case.id)
      elsif result == :validation_error
        @case = CaseExtendForPITDecorator.decorate @case
        @case.extension_deadline_yyyy = pit_params[:extension_deadline_yyyy]
        @case.extension_deadline_mm = pit_params[:extension_deadline_mm]
        @case.extension_deadline_dd = pit_params[:extension_deadline_dd]
        @case.reason_for_extending = pit_params[:reason_for_extending]
        render :extend_for_pit
      else
        flash[:alert] = "Unable to perform PIT extension on case #{@case.number}"
        redirect_to case_path(@case.id)
      end
    end

    # Was remove_pit_extension
    def destroy
      authorize @case, :remove_pit_extension?

      service = CaseRemovePITExtensionService.new current_user,
                                                  @case
      result = service.call

      if result == :ok
        flash[:notice] = 'Public Interest Test extensions removed'
        redirect_to case_path(@case.id)
      else
        flash[:alert] = "Unable to remove Public Interest Test extensions"
        redirect_to case_path(@case.id)
      end
    end
  end
end
