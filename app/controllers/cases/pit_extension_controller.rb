module Cases
  class PitExtensionController < BaseController
    before_action :set_case, only: [:extend_for_pit, :execute_extend_for_pit, :remove_pit_extension]

    # Was extend_for_pit
    def new
      extend_for_pit
    end

    # Was execute_extend_for_pit
    def create
      execute_extend_for_pit
    end

    # Was remove_pit_extension
    def destroy
      remove_pit_extension
    end

    # Original
    def extend_for_pit
      authorize @case

      @case = CaseExtendForPITDecorator.decorate @case
    end

    def execute_extend_for_pit
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

    def remove_pit_extension
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
