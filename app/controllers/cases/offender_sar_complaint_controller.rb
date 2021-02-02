module Cases
  class OffenderSarComplaintController < OffenderSarController

    before_action -> { set_decorated_case(params[:id]) }, only: [
      :reopen, :confirm_reopen
    ]

    include OffenderSARComplaintCasesParams

    def initialize
      super

      @correspondence_type = CorrespondenceType.offender_sar_complaint
      @correspondence_type_key = 'offender_sar_complaint'
    end


    def start_complaint
      params.merge!(:current_step => "link-offender-sar-case")
      params.merge!(:commit => true)
      params[@correspondence_type_key] = {}
      params[@correspondence_type_key].merge!("original_case_number" => params["number"])
      create
    end

    def reopen
      authorize @case, :can_be_reopened?
      if @case.standard_complaint?
        @case.object.external_deadline = @case.object.deadline_calculator.external_deadline
      end
      render :reopen      
    end 

    def confirm_reopen
      authorize @case, :can_be_reopened?
      service = CaseReopenService.new(
        current_user,
        @case,
        reopen_offender_sar_complaint_params
      )
      service.call
  
      if service.result == :ok
        flash[:notice] = "You have reopened case #{@case.number}."
        redirect_to case_path(@case)
      else
        @case.assign_attributes(reopen_offender_sar_complaint_params)
        render :reopen
      end       
    end

    def update
      @case = Case::Base.find(params[:id])
      authorize @case
      @case = @case.decorate
      preserve_step_state

      service = ComplaintCaseUpdaterService.new(current_user, @case, edit_params)
      service.call

      if service.result == :error
        render 'cases/edit' and return
      end

      if service.result == :ok
        flash[:notice] = t('cases.update.case_updated')
      elsif service.result == :no_changes
        flash[:alert] = "No changes were made"
      end

      set_permitted_events
      @case_transitions = @case.transitions.case_history.order(id: :desc).decorate
      redirect_to case_path(@case)
    end

    def set_case_types
      @case_types = ["Case::SAR::OffenderComplaint"]
    end

    def case_type
      Case::SAR::OffenderComplaint
    end

    def create_params
      create_offender_sar_complaint_params
    end

    def edit_params
      create_offender_sar_complaint_params
    end

    def update_params
      create_offender_sar_complaint_params
    end

    def process_closure_params
      process_offender_sar_complaint_closure_params
    end

    def process_date_responded_params
      respond_offender_sar_complaint_params
    end

    def session_state
      "#{@correspondence_type_key}_state".to_sym
    end

    def case_updater_service
      # overides base class method to utilise specific
      # service in complaint case updates
      ComplaintCaseUpdaterService
    end
  end
end
