class CaseLinkTypeValidator < ActiveModel::Validator
  ALLOWED_LINKS_BY_TYPE = {
    related: {
      'Case::FOI::Standard'         => ['Case::FOI::Standard',
                                        'Case::FOI::ComplianceReview',
                                        'Case::FOI::TimelinessReview',
                                        'Case::ICO::FOI'],
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
                                        'Case::ICO::FOI'],
      'Case::SAR'                   => ['Case::SAR',
                                        'Case::ICO::SAR'],
      'Case::ICO::SAR'              => ['Case::SAR',
                                        'Case::ICO::SAR'],
    },
    original: {
      'Case::ICO::FOI' => ['Case::FOI::Standard'],
      'Case::ICO::SAR' => ['Case::SAR'],
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
  def validate(record)
    if not self.class.classes_can_be_linked_with_type?(
             type: record.type,
             klass: record.case.class,
             linked_klass: record.linked_case.class
           )

      record.errors.add(
        :linked_case,
        :wrong_type,
        message: I18n.t('activerecord.errors.models.linked_case.wrong_type',
                        type: record.type,
                        case_class: record.case.class.to_s,
                        linked_case_class: record.linked_case.class.to_s)
      )

    end
  end
end
