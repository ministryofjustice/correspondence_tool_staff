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

      $('#case_message').closest('.form-group').toggle(this.$deliveryMethodEmail.is(':checked'))

      $('.dropzone').closest('.grid-row').toggle(this.$deliveryMethodPost.is(':checked'))

    } else {

      this.$deliveryMethodFields.hide();

    }
  }
};
