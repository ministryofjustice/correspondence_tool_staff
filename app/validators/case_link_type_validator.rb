class CaseLinkTypeValidator < ActiveModel::Validator

  attr_accessor :error_message

  ALLOWED_LINKS_BY_TYPE = {
    related: {
      'Case::FOI::Standard'         => ['Case::FOI::Standard',
                                        'Case::FOI::ComplianceReview',
                                        'Case::FOI::TimelinessReview',
                                        'Case::ICO::FOI',
                                        'Case::OverturnedICO::FOI'],
      'Case::FOI::TimelinessReview' => ['Case::FOI::Standard',
                                        'Case::FOI::ComplianceReview',
                                        'Case::FOI::TimelinessReview',
                                        'Case::ICO::FOI'],
      'Case::FOI::ComplianceReview' => ['Case::FOI::Standard',
                                        'Case::FOI::ComplianceReview',
                                        'Case::FOI::TimelinessReview',
                                        'Case::ICO::FOI'],
      'Case::ICO::FOI'              => ['Case::FOI::Standard',
                                        'Case::FOI::ComplianceReview',
                                        'Case::FOI::TimelinessReview',
                                        'Case::ICO::FOI',
                                        'Case::OverturnedICO::FOI'],
      'Case::SAR::Standard'         => ['Case::SAR::Standard',
                                        'Case::ICO::SAR',
                                        'Case::OverturnedICO::SAR',
                                        'Case::SAR::InternalReview'],
      'Case::SAR::InternalReview'   => ['Case::SAR::Standard',
                                        'Case::SAR::InternalReview',
                                        'Case::ICO::SAR',
                                        'Case::OverturnedICO::SAR'],
      'Case::ICO::SAR'              => ['Case::SAR::Standard',
                                        'Case::ICO::SAR',
                                        'Case::OverturnedICO::SAR'],
      'Case::OverturnedICO::SAR'    => ['Case::SAR::Standard',
                                        'Case::ICO::SAR'],
      'Case::OverturnedICO::FOI'    => ['Case::FOI::Standard',
                                        'Case::FOI::ComplianceReview',
                                        'Case::FOI::TimelinessReview',
                                        'Case::ICO::FOI'],
      'Case::SAR::Offender'         => ['Case::SAR::Offender',
                                        'Case::SAR::OffenderComplaint'],
    },
    original: {
      'Case::ICO::FOI'            => ['Case::FOI::Standard', 
                                      'Case::FOI::TimelinessReview', 
                                      'Case::FOI::ComplianceReview'],
      'Case::ICO::SAR'            => ['Case::SAR::Standard'],
      'Case::ICO::Base'           => ['Case::FOI::Standard', 
                                      'Case::FOI::TimelinessReview', 
                                      'Case::FOI::ComplianceReview',
                                      'Case::SAR::Standard'],
      'Case::OverturnedICO::SAR'  => ['Case::SAR::Standard'],
      'Case::OverturnedICO::FOI'  => ['Case::FOI::Standard'],
      'Case::SAR::OffenderComplaint'  => ['Case::SAR::Offender'],
      'Case::SAR::InternalReview'  => ['Case::SAR::Standard'],
    },
    original_appeal: {
      'Case::OverturnedICO::SAR'  => ['Case::ICO::SAR'],
      'Case::OverturnedICO::FOI'  => ['Case::ICO::FOI'],
    },
  }.with_indifferent_access

  class << self
    def classes_can_be_linked_with_type?(type:, klass:, linked_klass:)
      if klass.to_s.in?(ALLOWED_LINKS_BY_TYPE[type])
        linked_klass.to_s.in?(ALLOWED_LINKS_BY_TYPE[type][klass.to_s])
      else
        false
      end
    end
  end

  # Validate whether type of case link is valid or not for a pair of cases.
  def validate(case_link)
    unless case_link.linked_case.present?
      return
    end

    case_class = case_link.case.class
    linked_class = case_link.linked_case.class
    unless self.class.classes_can_be_linked_with_type?(
             type: case_link.type,
             klass: case_class,
             linked_klass: linked_class
           )
      case_class_name = I18n.t("cases.types.#{case_class}")
      linked_class_name = I18n.t("cases.types.#{linked_class}")
      case_link.errors.add(
        :linked_case,
        :wrong_type,
        message: I18n.t('activerecord.errors.models.linked_case.wrong_type',
                        type: case_link.type,
                        case_class: case_class_name,
                        linked_case_class: linked_class_name)
      )
    end
  end
end
