moj.Modules.CaseCreation = {
  $receivedBy          : $('#received-by'),

  $receivedByEmail  : $('#case_received_by_email'),
  $receivedByPost   : $('#case_received_by_post'),

  $receivedByFields : $('#received-by-fields'),

  init: function () {
    var self = this;

    self.showHideRefusalReceiveByFields();

    //Bind events
    self.$receivedBy.on('change', ':radio', function(){

      self.showHideRefusalReceiveByFields();

    });
  },

  showHideRefusalReceiveByFields: function (){
    if (this.$receivedBy.find(':radio').is(':checked')){

      this.$receivedByFields.show();

      $('#case_message').closest('.form-group').toggle(this.$receivedByEmail.is(':checked'))

      $('.dropzone').closest('.grid-row').toggle(this.$receivedByPost.is(':checked'))

    } else {

      this.$receivedByFields.hide();

    }
  }
};
