module SarInternalReviewCaseForm
  extend ActiveSupport::Concern

  STEPS = %w[link-sar-case
             confirm-sar
             case-details].freeze

  def steps
    STEPS
  end

  private

  def validate_link_sar_case(params)
    original_case_number = (params[:original_case_number] || '').strip
    case_link = LinkedCase.new(
      linked_case_number: original_case_number,
      type: :original
    )
    if case_link.valid?
      original_case = case_link.linked_case
      if not Pundit.policy(object.creator, original_case).show?
        add_errors_for_original_case(
          I18n.t('activerecord.errors.models.case/sar/internal_review.original_case_number.not_authorised'))
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
    fields_subject_details = [
      :delivery_method,
      :email,
      :message,
      :name,
      :postal_address,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :requester_type,
      :subject,
      :subject_full_name,
      :subject_type,
      :third_party,
      :third_party_relationship,
      :reply_method,
    ]
    fields_subject_details.each do | single_field |
      params[single_field] = object.original_case.send(single_field)
    end

    params
  end

  def params_after_step_case_details(params)
    params.merge!(original_case_id: object.original_case_id)
    params.delete(:original_case_number)

    params
  end

end
