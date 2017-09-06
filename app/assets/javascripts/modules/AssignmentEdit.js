moj.Modules.AssignmentEdit = {
  $assignmentActions    : $('#js-assigment-actions'),

  $rejected             : $('#assignment_state_rejected'),
  $accepted             : $('#assignment_state_accepted'),

  $rejectedReasons      : $('#js-rejected-reasons'),

  init: function () {
    var self = this;

    self.showHideRejectionFields();

    //Bind events
    self.$assignmentActions.on('change', ':radio', function(){

      self.showHideRejectionFields();

    });
  },

  showHideRejectionFields: function (){
    if (this.$rejected.is(':checked')){

      this.$rejectedReasons.show().find('textarea').focus();

    } else {

      this.$rejectedReasons.hide();

    }
  }
};
