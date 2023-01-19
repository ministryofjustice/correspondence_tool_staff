moj.Modules.RecordSentToSscl = {
  $removeDateButton: $('.sent-to-sscl-remove-date'),
  $dayField: $('#offender_sar_sent_to_sscl_at_dd'),
  $monthField: $('#offender_sar_sent_to_sscl_at_mm'),
  $yearField: $('#offender_sar_sent_to_sscl_at_yyyy'),
  $reasonBlock: $('#remove-send-to-sscl-reason'),

  init: function () {
    var self = this;

    self.initializeRemoveDateButton(self);
  },

  initializeRemoveDateButton: function(self) {
    self.$removeDateButton.click(function(e) {
      e.preventDefault();
      self.removeDate(self);
      self.revealReason(self);
    });
  },

  removeDate: function(self) {
    self.$dayField.val('');
    self.$monthField.val('');
    self.$yearField.val('');
  },

  revealReason: function(self) {
    self.$removeDateButton.hide();
    self.$reasonBlock.removeClass('hidden');
  }
};
