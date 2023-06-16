if defined?(Mime) && Mime[:docx].nil?
  Mime::Type.register "application/vnd.openxmlformats-officedocument.wordprocessingml.document", :docx
end
