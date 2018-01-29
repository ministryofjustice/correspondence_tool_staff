moj.Modules.CaseCreation = {
  $deliveryMethod       : $('#delivery-method'),

  $deliveryMethodEmail  : $('#case_delivery_method_sent_by_email'),
  $deliveryMethodPost   : $('#case_delivery_method_sent_by_post'),

  $deliveryMethodFields : $('#delivery-method-fields'),

  init: function () {
    var self = this;

    self.showHideDeliveryMethodFields();

    //Bind events
    self.$deliveryMethod.on('change', ':radio', function(){

      self.showHideDeliveryMethodFields();

    });
  },

  showHideDeliveryMethodFields: function (){
    if (this.$deliveryMethod.find(':radio').is(':checked')){

      this.$deliveryMethodFields.show();

      if (this.$deliveryMethodEmail.is('checked')) {
        $('#case_message').closest('.form-group').show();
      } else {
        $('#case_message').closest('.form-group').hide();
      }

      if (this.$deliveryMethodPost.is('checked')) {
        $('.dropzone').closest('.grid-row').show();
      } else {
        $('.dropzone').closest('.grid-row').show();
      }

    } else {

      this.$deliveryMethodFields.hide();

      $('#case_message').closest('.form-group').hide();

      $('.dropzone').closest('.grid-row').hide();

    }
  }
};
