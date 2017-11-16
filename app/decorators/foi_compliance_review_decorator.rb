class FoiComplianceReviewDecorator < Draper::Decorator
  delegate_all

  def pretty_type
    'FOI - Internal review for compliance'
  end
end
