moj.Modules.PartialCaseFlagsActions = {

  $is_partial_case            : $('#is_partial_case'),
  $further_actions_required   : $('#further_actions_required'),
  $partial_flags_form         : $('#edit_case_sar_partial_flags'),

  init: function () {
    var self = this;

    self.setFlagsValue();
    self.$is_partial_case.on('click', function(e){
      e.preventDefault();
      self.callFlagsUpdateService();
    });
    self.$further_actions_required.on('click', function(e){
      e.preventDefault();
      self.callFlagsUpdateService();
    });
  },

  callFlagsUpdateService: function (){
    var url = this.$partial_flags_form.attr('action');
    var submited_data = this.collectFlags();
    $.post(url, submited_data, function(data) {
      moj.Modules.PartialCaseFlagsActions.$is_partial_case.val(submited_data.is_partial_case ? 1 : 0);
      moj.Modules.PartialCaseFlagsActions.$further_actions_required.val(submited_data.further_actions_required ? 1 : 0);
      moj.Modules.PartialCaseFlagsActions.setFlagsValue();
      moj.Modules.PartialCaseFlagsActions.addNewTransitions(data.transitions);
    })
    .fail(function() {
      location.reload();
    })
  },

  collectFlags: function () {
    var is_partial_case = false;
    var further_actions_required = false;
    if (this.$is_partial_case.is(':checked')) {
      is_partial_case = true
    }
    if (this.$further_actions_required.is(':checked')) {
      further_actions_required = true;
    }
    return {is_partial_case: is_partial_case, further_actions_required: further_actions_required};
  },

  setFlagsValue: function (){
    var is_partial_case = this.$is_partial_case.val();
    var further_actions_required = this.$further_actions_required.val();

    this.$is_partial_case.prop('checked', false);
    this.$further_actions_required.prop('checked', false);
    this.$is_partial_case.prop('disabled', false);
    this.$further_actions_required.prop('disabled', false);

    if (is_partial_case === '1') {
      this.$is_partial_case.prop('checked', true);
    } else {
      this.$further_actions_required.prop('disabled', true);
    }
    if (further_actions_required === '1') {
      this.$is_partial_case.prop('disabled', true);
      this.$is_partial_case.prop('checked', true);
      this.$further_actions_required.prop('checked', true);
    }
  },

  addNewTransitions: function (transitions){
    $.each(transitions , function(index, transition) { 
      $('#case-history').prepend('<tr><td>' + transition.timestamp + '</td><td>' + 
                                      transition.user + '</td><td>' + 
                                      transition.team + '</td><td>' + 
                                      transition.message + '</td></tr>');
    });
    
  }

};
