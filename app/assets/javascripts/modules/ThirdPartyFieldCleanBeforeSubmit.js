moj.Modules.ThirdPartyFieldCleanBeforeSubmit = {
  init: function() {
    var self = this;

    var element_id = $('#code_for_reason_of_other').val();
    var input_for_other_reason = "#offender_sar_reason_for_lateness_id_" + element_id

    $('#new_offender_sar').submit(function() {
      self.clearThirdPartyFields("offender_sar");
    });

    $('#edit_offender_sar').submit(function() {
      self.clearThirdPartyFields("offender_sar");
      self.clearNotesForReasonForLateness(input_for_other_reason);
    });

    $('#new_offender_sar_complaint').submit(function() {
      self.clearThirdPartyFields("offender_sar_complaint");
    });

    $('#edit_offender_sar_complaint').submit(function() {
      self.clearThirdPartyFields("offender_sar_complaint");
    });

  },

  clearThirdPartyFields: function (case_type){
    if (($("#" + case_type + "_third_party_false").is(":checked")) ||
    ($("#" + case_type + "_recipient_subject_recipient").is(":checked"))) {
      $("#" + case_type + "_third_party_relationship").val('');
      $("#" + case_type + "_third_party_name").val('');
      $("#" + case_type + "_third_party_company_name").val('');
      $("#" + case_type + "_postal_address").val('');
    }
  }, 

  clearNotesForReasonForLateness: function (input_for_other_reason) {
    if (!$(input_for_other_reason).is(':checked')) {
      $("#offender_sar_reason_for_lateness_note").val('')
    }
  }

};
