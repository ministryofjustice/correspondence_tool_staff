module ViewsHelper
  def get_sub_heading(kase, key_path = "")
    if kase.offender_sar? && kase.rejected?
      t4c(kase, key_path, "rejected")
    else
      t4c(kase, key_path, "sub_heading", case_type: kase.decorate.pretty_type)
    end
  end

  def formatted_data_request_area_type(data_request_area_type)
    case data_request_area_type
    when 'prison'
      'prison'
    when 'branston'
      'Branston'
    when 'branston_registry'
      'Branston registry'
    when 'mappa'
      'MAPPA'
    when 'probation'
      'probation'
    else
      data_request_area_type.tr('_', ' ') # Default formatting if type does not match
    end
  end

end
