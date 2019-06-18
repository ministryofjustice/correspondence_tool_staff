module Cases
  class OffenderSarController < CasesController
    include NewCase
    include OffenderSARCasesParams

    def initialize
      @correspondence_type = CorrespondenceType.offender_sar
      @correspondence_type_key = 'offender_sar'

      super
    end

    def new
      permitted_correspondence_types
      #prepare_new_case

      @case = OffenderSARCaseForm.new(session)
      step = params[:step].present? && params[:step] != 'new' ? params[:step] : @case.steps.first

      # @todo: Why does current_step need to be set? is it something OffenderSARCaseForm
      # can figure out itself?
      @case.current_step = step
    end

    def create
      permitted_correspondence_types
      #prepare_new_case

      @case = OffenderSARCaseForm.new(session)

      @case.case.creator = current_user #to-do Remove when we use the case create service
      @case.case.subject = "Offender SAR" #to-do Remove when we use the case create service

      @case.assign_params(create_params) if create_params
      @case.current_step = params[:current_step]

      if @case.valid_attributes?(create_params)
        if @case.valid?
          if @case.save
            session[:offender_sar_state] = nil
            redirect_to case_path(@case.case) and return
          end
        end
        @case.session_persist_state(create_params)
        get_next_step(@case)
        redirect_to step_case_sar_offenders_path + "/#{@case.current_step}"
      else
        render :new
      end
    end

    def case_type
      Case::SAR::Offender
    end

    def create_params
      create_offender_sar_params
    end

    def edit_params
      edit_offender_sar_params
    end

    def process_closure_params
      process_offender_sar_closure_params
    end

    def respond_params
      respond_offender_sar_params
    end

    def process_date_responded_params
      respond_offender_sar_params
    end

    def cancel
      session[:offender_sar_state] = nil
      redirect_to offender_sar_new_case_path
    end

    private

    # @todo: Should this be in Steppable?
    def get_next_step(obj)
      obj.current_step = params[:current_step]

      if params[:previous_button]
        obj.previous_step
      elsif params[:commit]
        obj.next_step
      end
    end
  end
end
