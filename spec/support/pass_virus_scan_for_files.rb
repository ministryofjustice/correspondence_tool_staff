def pass_virus_scan_for_all_files!
  allow(VirusScanJob).to receive(:perform_later).with(anything) do |attachment_id|
    CaseAttachment.find(attachment_id).virus_scan_passed!
  end
end
