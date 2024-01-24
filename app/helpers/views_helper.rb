module ViewsHelper
  def get_headings(kase, correspondence_type)
    if kase.current_state == 'rejected' && correspondence_type.abbreviation == CorrespondenceType.offender_sar.abbreviation
      t4c(kase, 'cases.new', 'offender_sar.rejected', case_type: kase.decorate.pretty_type)
    else
      t4c(kase, 'cases.new', 'sub_heading', case_type: kase.decorate.pretty_type)
    end
  end
end
