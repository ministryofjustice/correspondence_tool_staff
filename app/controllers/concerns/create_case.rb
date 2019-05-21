module CreateCase
  extend ActiveSupport::Concern

  def create_case_for_type(correspondence_type, correspondence_type_key)
    begin
      service = CaseCreateService.new current_user, correspondence_type_key, params
      authorize service.case_class, :can_add_case?

      service.call
      @case = service.case

      case service.result
      when :assign_responder
        flash[:creating_case] = true
        flash[:notice] = service.flash_notice
        redirect_to new_case_assignment_path @case
      else # including :error
        @case = @case.decorate
        @case_types = correspondence_type.sub_classes.map(&:to_s)
        @s3_direct_post = s3_uploader_for @case, 'requests'
        render :new
      end
    rescue ActiveRecord::RecordNotUnique
      flash.now[:notice] = t('activerecord.errors.models.case.attributes.number.duplication')
      render :new
    end
  end
end
