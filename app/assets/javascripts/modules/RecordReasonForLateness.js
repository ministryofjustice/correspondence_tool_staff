moj.Modules.RecordReasonForLateness = {

  init: function () {
    var self = this;

    var element_id = $('#code_for_reason_of_other').val();
    var input_for_other_reason = "#offender_sar_reason_for_lateness_id_" + element_id
    self.showReasonNote(input_for_other_reason);
    $('input[name="offender_sar[reason_for_lateness_id]"]').change(function(){
      self.showReasonNote(input_for_other_reason);
    });
  },

  showReasonNote: function (input_for_other_reason){
    if ($(input_for_other_reason).is(':checked')) {
      $('#reason_for_note_group').show();
    } else {
      $('#reason_for_note_group').hide();
    }
  }

};
