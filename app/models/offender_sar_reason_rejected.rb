class OffenderSarReasonRejected < ApplicationRecord

  enum reason_rejected: {
    cctv_bwcv: "cctv_bwcv",
    change_of_name_certificate: "change_of_name_certificate",
    court_data_request: "court_data_request",
    data_previously_requested: "data_previously_requested",
    further_identification: "further_identification",
    identification_for_ex_inmate_probation: "identification_for_ex_inmate_probation",
    illegible_handwriting_unreadable_content: "illegible_handwriting_unreadable_content",
    id_required: "id_required",
    invalid_authority: "invalid_authority",
    medical_data: "medical_data",
    observation_book_entries: "observation_book_entries",
    police_data: "police_data",
    social_services_data: "social_services_data",
    telephone_recordings_logs: "telephone_recordings_logs",
    telephone_transcripts: "telephone_transcripts",
    third_party_identification: "third_party_identification",
    what_data_no_data_requested: "what_data_no_data_requested",
    other: "other",
  }
end
