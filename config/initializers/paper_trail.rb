Rails.application.config.to_prepare do
  PaperTrail.serializer = CTSPapertrailSerializer
end
