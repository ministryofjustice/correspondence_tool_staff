moj.Modules.ThirdPartyFieldCleanBeforeSubmit = {
  init: function() {
    var self = this;

    $('#new_offender_sar').submit(function() {
      self.clearThirdPartyFields("offender_sar");
    });

    $('#edit_offender_sar').submit(function() {
      self.clearThirdPartyFields("offender_sar");
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
  }

};
