module Cases
  class FOIController < CasesController
    include NewCase
    include FOICasesParams

    before_action -> { set_case(params[:id]) }, only: %i[send_back confirm_send_back]

    def initialize
      @correspondence_type = CorrespondenceType.foi
      @correspondence_type_key = "foi"

      super
    end

    def send_back
      authorize @case, :can_send_back?

      set_permitted_events
      render "cases/foi/send_back"
    end

    def confirm_send_back
      authorize @case, :can_send_back?
      set_permitted_events

      service = CaseSendBackService.new(
        user: current_user,
        kase: @case,
        comment: params[:extra_comment],
      )
      result = service.call

      if result == :ok
        flash[:notice] = "The case has been sent back to responder for change."
        redirect_to case_path(@case)
      else
        @case = @case.decorate
        flash[:alert] = service.error_message
        render :send_back
      end
    end

    def new
      permitted_correspondence_types
      new_case_for @correspondence_type
    end

    def case_type
      foi_type = params.dig(@correspondence_type_key, "type")
      return Case::FOI::Standard if foi_type.blank?

      Case::FOI::Standard.factory(foi_type)
    end

    def create_params
      create_foi_params
    end

    def edit_params
      edit_foi_params
    end

    def process_closure_params
      process_foi_closure_params
    end

    def respond_params
      respond_foi_params
    end

    def process_date_responded_params
      respond_foi_params
    end
  end
end
