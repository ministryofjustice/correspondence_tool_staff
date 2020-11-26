class Case::SAR::OffenderComplaint < Case::SAR::Offender

  include LinkableOriginalCase

  validates_presence_of :original_case
  after_create :stamp_on_original_case

  jsonb_accessor :properties,
                 complaint_type: :string,
                 priority: :string

  validates :complaint_type, presence: true
  validates :priority, presence: true

  enum complaint_type: {
    standard:  'standard',
    ico: 'ico',
    litigation: 'litigation',
  }

  enum priority: {
    normal:  'normal',
    high: 'high',
  }

  class << self
    def type_abbreviation
      'OFFENDER_SAR_COMPLAINT'
    end
  end

  def offender_sar_complaint?
    true
  end

  def type_of_offender_sar?
    true
  end

  def offender_sar?
    false
  end

  private

  def stamp_on_original_case
    self.original_case.state_machine.add_note_to_case!(
      acting_user: self.creator,
      acting_team: self.creator.case_team(self.original_case),
      message: I18n.t(
        'common.case/offender_sar.complaint_case_link_message',
        creation_date: self.created_at.to_date))
  end

end
