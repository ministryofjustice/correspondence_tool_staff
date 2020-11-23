moj.Modules.OffenderComplaintConfirmAction = {
  $complaintConfirmChoices    : $('#js-offender-sar-confirm-actions  '),

  $complaintConfirmYes        : $('#offender_sar_complaint_original_case_number_yes'),
  $complaintConfirmNo         : $('#offender_sar_complaint_original_case_number_yes'),

  $complaintContinueBtn       : $('#btn-offender-sar-complaint-continue'),

  init: function () {
    var self = this;
    self.$complaintConfirmChoices.on('change', ':radio', function(){
      self.enableContinueBtn();
    });
  },

  enableContinueBtn: function (){
    if (this.$complaintConfirmYes.is(':checked')){
      this.$complaintContinueBtn.prop('disabled', false);
    } else {
      this.$complaintContinueBtn.prop("disabled", true);
    }
  }
};
