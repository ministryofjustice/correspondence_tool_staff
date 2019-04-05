module OverturnedCase
  extend ActiveSupport::Concern

  def new_overturned_ico_for overturned_case_class
    authorize overturned_case_class
    service = NewOverturnedIcoCaseService.new(params[:id])
    service.call
    if service.error?
      @case = service.original_ico_appeal.decorate
      render :show, :status => :bad_request
    else
      @case = service.overturned_ico_case.decorate
      @original_ico_appeal = service.original_ico_appeal
      set_correspondence_type(overturned_case_class.type_abbreviation.downcase)
      render :new
    end
  end
end