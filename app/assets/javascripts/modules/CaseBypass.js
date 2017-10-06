moj.Modules.CaseBypass = {
  $bypassActions    : $('#js-bypass-actions'),

  $needsClearance       : $('#bypass_approval_press_office_approval_required_true'),
  $bypassClearance      : $('#bypass_approval_press_office_approval_required_false'),

  $bypassReasons      : $('#js-bypass-reasons'),

  init: function () {
    var self = this;

    self.showHideBypassFields();

    //Bind events
    self.$bypassActions.on('change', ':radio', function(){

      self.showHideBypassFields();

    });
  },

  showHideBypassFields: function (){
    if (this.$bypassClearance.is(':checked')){

      this.$bypassReasons.show().find('textarea').focus();

    } else {

      this.$bypassReasons.hide();

    }
  }
};
