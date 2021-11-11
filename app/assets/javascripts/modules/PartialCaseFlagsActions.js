moj.Modules.PartialCaseFlagsActions = {

  $is_not_partial_case            : $('#offender_sar_is_partial_case_false'),
  $is_partial_case                : $('#offender_sar_is_partial_case_true'),

  $second_partial_flag_awaiting   : $('#offender_sar_further_actions_required_awaiting_response'),
  $second_partial_flag_no         : $('#offender_sar_further_actions_required_no'),
  $second_partial_flag_yes        : $('#offender_sar_further_actions_required_yes'),
  $partial_flags_info_panel       : $('#partial_case_info_panel'),

  $letter_sent_date_dd            : $('#offender_sar_partial_case_letter_sent_dated_dd'),
  $letter_sent_date_mm            : $('#offender_sar_partial_case_letter_sent_dated_mm'),
  $letter_sent_date_yyyy          : $('#offender_sar_partial_case_letter_sent_dated_yyyy'),
  $further_actions_required_init  : $('#further_actions_required_init'),
  $is_partial_case_init           : $('#is_partial_case_init'),
  

  init: function () {
    var self = this;

    self.init_ui();
    self.hidePartialSecondFlagsPanel();
    
    self.$is_not_partial_case.on('change', function(){
      self.hidePartialSecondFlagsPanel();
    });

    self.$is_partial_case.on('change', function(){
      self.hidePartialSecondFlagsPanel();
    });

    $('#edit_offender_sar').submit(function() {
      self.clearParticalSecondFlagsFields();
    });
  },

  init_ui: function () {
    if (this.$is_partial_case_init.val() == '0') {
      this.$is_not_partial_case.prop('checked', true);
    }
  },

  hidePartialSecondFlagsPanel: function (){
    if (this.$is_not_partial_case.is(':checked')) {
      this.$partial_flags_info_panel.hide();
    } else {
      this.$partial_flags_info_panel.show()
    }
  }, 

  clearParticalSecondFlagsFields: function (){
    if (this.$is_not_partial_case.is(':checked')) {
      this.$letter_sent_date_dd.val('');
      this.$letter_sent_date_mm.val('');
      this.$letter_sent_date_yyyy.val('');
  
      this.$second_partial_flag_awaiting.prop('checked', false);
      if (this.$further_actions_required_init.val() == '1') {
        this.$second_partial_flag_no.prop('checked', true);
      }
      this.$second_partial_flag_yes.prop('checked', false);
    }
  },

};
