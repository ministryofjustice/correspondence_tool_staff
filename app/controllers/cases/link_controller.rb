module Cases
  class LinkController < BaseController
    before_action :set_case, only: [:new_case_link, :destroy_case_link, :execute_new_case_link]

    def new_case_link
      authorize @case

      @case = CaseLinkDecorator.decorate @case
    end

    def execute_new_case_link
      authorize @case, :new_case_link?

      link_case_number = params[:case][:linked_case_number]

      service = CaseLinkingService.new current_user, @case, link_case_number
      result = service.create


      if result == :ok
        flash[:notice] = "Case #{link_case_number} has been linked to this case"
        redirect_to case_path(@case)
      elsif result == :validation_error
        @case = CaseLinkDecorator.decorate @case
        @case.linked_case_number = link_case_number
        render :new_case_link
      else
        flash[:alert] = "Unable to create a link to case #{link_case_number}"
        redirect_to case_path(@case)
      end
    end

    def destroy_case_link
      authorize @case, :new_case_link?

      linked_case_number = params[:linked_case_number]

      service = CaseLinkingService.new current_user, @case, linked_case_number

      result = service.destroy

      if result == :ok
        flash[:notice] = "The link to case #{linked_case_number} has been removed."
        redirect_to case_path(@case)
      else
        flash[:alert] = "Unable to remove the link to case #{linked_case_number}"
        redirect_to case_path(@case)
      end
    end

    def new_linked_cases_for
      set_correspondence_type(params.fetch(:correspondence_type))
      @link_type = params[:link_type].strip

      respond_to do |format|
        format.js do
          if process_new_linked_cases_for_params
            response = render_to_string(
              partial: "cases/#{ @correspondence_type_key }/case_linking/linked_cases",
              locals: {
                linked_cases: @linked_cases.map(&:decorate),
                link_type: @link_type,
              }
            )

            render status: :ok, json: { content: response, link_type: @link_type }.to_json

          else
            render status: :bad_request,
                   json: { linked_case_error: @linked_case_error,
                           link_type: @link_type }.to_json
          end
        end
      end
    end
  end
end
