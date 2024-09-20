module ViewsHelper
  def get_sub_heading(kase, key_path = "")
    if kase.offender_sar? && kase.rejected?
      t4c(kase, key_path, "rejected")
    else
      t4c(kase, key_path, "sub_heading", case_type: kase.decorate.pretty_type)
    end
  end

  def formatted_data_request_area_type(data_request_area_type)
    area_types = {
      "prison" => "prison",
      "branston" => "Branston",
      "branston_registry" => "Branston Registry",
      "mappa" => "MAPPA",
      "probation" => "probation",
    }

    area_types[data_request_area_type]
  end
end
