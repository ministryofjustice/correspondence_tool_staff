moj.Modules.CaseCreation = {
  $deliveryMethod       : $('#delivery-method'),

  $deliveryMethodEmail  : $('#case_foi_delivery_method_sent_by_email'),
  $deliveryMethodPost   : $('#case_foi_delivery_method_sent_by_post'),

  $deliveryMethodFields : $('#delivery-method-fields'),

  init: function () {
    var self = this;

    if(self.$deliveryMethod.length > 0) {
      self.showHideDeliveryMethodFields();

      //Bind events
      self.$deliveryMethod.on('change', ':radio', function () {
        self.showHideDeliveryMethodFields();
      });
    }

    // For linking to original case
    $('#xhr-search-button').click(function () {
      self.getCaseDetails(this);
    });

    $('#cases_case_number').on('keypress', function(e){
      if (e.keyCode === 13 ) {
        e.preventDefault()
        self.getCaseDetails(document.getElementById('xhr-search-button'));
      }
    })

    // Undo actions
    $('.js-original-case-and-friends')
    .on('click','.js-remove-original', function (e) {
      self.removeOriginalCase(e);
    }).on('click', 'a.js-exclude-case', function (e){
      self.excludeOtherRelatedCase(e);
    })
  },

  showHideDeliveryMethodFields: function () {
    if (this.$deliveryMethod.find(':radio').is(':checked')){

      this.$deliveryMethodFields.show();

      if (this.$deliveryMethodEmail.is(':checked')) {
        $('#case_foi_message').closest('.form-group').show();
      } else {
        $('#case_foi_message').closest('.form-group').hide();
      }

      if (this.$deliveryMethodPost.is(':checked')) {
        $('.dropzone').closest('.grid-row').show();
      } else {
        $('.dropzone').closest('.grid-row').hide();
      }

    } else {

      this.$deliveryMethodFields.hide();

      $('#case_message').closest('.form-group').hide();

      $('.dropzone').closest('.grid-row').hide();

    }
  },

  getCaseDetails: function (button) {
    $.ajax({
        url: $(button).data('url'),
        data: { 'original_case_number': document.getElementById('original_case_number').value,
                'correspondence_type': document.getElementById('correspondence_type').value,
              }
    });
  },

  excludeOtherRelatedCase: function (event) {
    event.preventDefault();
    var $tr = $(event.target).closest('tr');
    var $tbody = $tr.closest('tbody');
    var $otherCasesSection = $tr.closest('.grid-row.form-group');

    //Remove the specific row
    $tr.remove();

    // Hide the table if there is no other rows
    if ($tbody.children().length === 0) {
      $otherCasesSection.remove();
    }
  },

  removeOriginalCase: function (event) {
    event.preventDefault()
    var results = document.querySelector('.js-original-case-and-friends');
    var message = 'This will remove the original case and any related cases below.\nDo you wish to continue?';

    if (confirm( message )) {
      results.innerHTML = '';
      document.getElementById('cases_case_number').focus();
    }
  }
};
