module SarInternalReviewFormValidators
  extend ActiveSupport::Concern

  def validate_case_details(params)
    object.assign_attributes(params)
  end

end
