module OverturnedCase
  extend ActiveSupport::Concern

  def new_overturned_ico_for(overturned_case_class)
    authorize overturned_case_class

    service = NewOverturnedICOCaseService.new(params[:id])
    service.call

    if service.error?
      @case = service.original_ico_appeal.decorate
      render "/cases/show", status: :bad_request
    else
      @case = service.overturned_ico_case.decorate
      @original_ico_appeal = service.original_ico_appeal
      render "/cases/#{@correspondence_type_key}/new"
    end
  end
end
