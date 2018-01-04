if LogStasher.enabled?
  LogStasher.add_custom_fields do |fields|
    fields[:user] = current_user && current_user.email
  end

  LogStasher.add_custom_fields_to_request_context do |fields|
    fields[:user] = current_user && current_user.email
  end
end
