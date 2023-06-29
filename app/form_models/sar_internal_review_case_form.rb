module SarInternalReviewCaseForm
  extend ActiveSupport::Concern

  STEPS = %w[link-sar-case
             confirm-sar
             case-details].freeze

  ORIGINAL_SAR_ATTRIBUTES_TO_COPY = %i[
    delivery_method
    email
    name
    postal_address
    requester_type
    subject
    subject_full_name
    subject_type
    third_party
    third_party_relationship
    reply_method
  ].freeze

  def steps
    STEPS
  end

  def original_sar_attributes_to_copy
    ORIGINAL_SAR_ATTRIBUTES_TO_COPY
  end

private

  def validate_link_sar_case(params)
    original_case_number = (params[:original_case_number] || "").strip
    case_link = LinkedCase.new(
      linked_case_number: original_case_number,
      type: :original,
    )
    if case_link.valid?
      original_case = case_link.linked_case
      if !Pundit.policy(object.creator, original_case).show?
        add_errors_for_original_case(
          I18n.t("activerecord.errors.models.case/sar/internal_review.attributes.original_case.not_authorised"),
        )
      else
        object.original_case_id = original_case.id
        object.validate_original_case
        object.validate_original_case_not_already_related
      end
    else
      add_errors_for_original_case(case_link.errors[:linked_case_number].join(". "))
    end
  end

  def add_errors_for_original_case(message)
    object.errors.add(:original_case_number, message)
  end

  def params_after_step_link_sar_case(params)
    params.merge!(original_case_id: object.original_case_id)

    params
  end

  def params_after_step_confirm_sar(params)
    params.merge!(original_case_id: object.original_case_id)
    params.delete(:original_case_number)
    original_sar_attributes_to_copy.each do |single_field|
      params[single_field] = object.original_case.send(single_field)
    end
    params
  end
end
