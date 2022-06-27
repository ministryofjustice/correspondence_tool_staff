module Cases
  class LinksController < ApplicationController
    include SetupCase

    before_action :set_case, only: [:new, :create, :destroy]

    def new
      authorize @case, :new_case_link?
      @case = CaseLinkDecorator.decorate @case
    end

    def create
      authorize @case, :new_case_link?

      link_case_number = params[:case][:number_to_link]
      service = CaseLinkingService.new current_user, @case, link_case_number
      result = service.create

      if result == :ok
        flash[:notice] = "Case #{link_case_number} has been linked to this case"
        redirect_to case_path(@case)
      elsif result == :validation_error
        @case = CaseLinkDecorator.decorate @case
        @case.linked_case_number = link_case_number
        render :new
      else
        flash[:alert] = "Unable to create a link to case #{link_case_number}"
        redirect_to case_path(@case)
      end
    end

    def destroy
      authorize @case, :new_case_link?

      linked_case_number = params[:id] # NOTE: id is a valid case number
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
  end
end
