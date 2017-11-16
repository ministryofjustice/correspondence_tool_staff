class FoiTimelinessReviewDecorator < Draper::Decorator
  delegate_all

  def pretty_type
    'FOI - Internal review for timeliness'
  end
end
