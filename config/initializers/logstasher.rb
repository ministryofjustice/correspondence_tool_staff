if LogStasher.enabled?
  LogStasher.add_custom_fields do |fields|
    # This block is run in application_controller context,
    # so you have access to all controller methods
    fields[:user] = current_user && current_user.email
    # fields[:site] = request.path =~ /^\/api/ ? 'api' : 'user'

    # If you are using custom instrumentation, just add it to logstasher custom fields
    # LogStasher.custom_fields << :myapi_runtime
  end

  LogStasher.add_custom_fields_to_request_context do |fields|
    # This block is run in application_controller context,
    # so you have access to all controller methods
    # You can log custom request fields using this block
    fields[:user] = current_user && current_user.email
    # fields[:site] = request.path =~ /^\/api/ ? 'api' : 'user'
  end
end
