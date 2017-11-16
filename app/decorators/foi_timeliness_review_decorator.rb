class FoiTimelinessReviewDecorator < CaseDecorator
  delegate_all

  def pretty_type
    case type
    when 'FoiComplianceReview'
      'FOI - Internal review for compliance'
    when 'FoiTimelinessReview'
      'FOI - Internal review for timeliness'
    when "Case"
      'FOI'
    else
      raise 'type does not exist'
    end
  end
end
