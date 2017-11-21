class FoiTimelinessReview < Case
  validate :check_is_flagged

  def check_is_flagged
    unless current_state.in?([nil, 'unassigned'])
      errors.add(:base, 'Internal reviews must be flagged for clearance') unless flagged?
    end
  end
end
