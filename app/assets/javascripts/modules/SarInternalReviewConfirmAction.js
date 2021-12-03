moj.Modules.SarInternalReviewConfirmAction = {
  $internalReviewConfirmChoices    : $('#js-sar-internal-review-confirm-actions'),

  $internalReviewConfirmYes        : $('#sar_internal_review_original_case_number_yes'),
  $internalReviewConfirmNo         : $('#sar_internal_review_original_case_number_yes'),

  $internalReviewContinueBtn       : $('#btn-sar-internal-review-continue'),

  init: function () {
    var self = this;
    self.$internalReviewConfirmChoices.on('change', ':radio', function(){
      self.enableContinueBtn();
    });
  },

  enableContinueBtn: function (){
    if (this.$internalReviewConfirmYes.is(':checked')){
      this.$internalReviewContinueBtn.prop('disabled', false);
    } else {
      this.$internalReviewContinueBtn.prop("disabled", true);
    }
  }
};
