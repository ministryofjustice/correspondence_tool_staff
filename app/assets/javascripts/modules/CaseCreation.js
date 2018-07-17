moj.Modules.CaseCreation = {
  $deliveryMethod       : $('#delivery-method'),

  $deliveryMethodEmail  : $('#case_foi_delivery_method_sent_by_email'),
  $deliveryMethodPost   : $('#case_foi_delivery_method_sent_by_post'),

  $deliveryMethodFields : $('#delivery-method-fields'),

  $originalCaseFields: $('#js-search-for-case .js-original-case'),
  $originalCaseInput: $('#case_ico_original_case_number'),
  $relatedCaseInput: $('#case_ico_related_case_number'),
  $relatedCaseFields: $('#js-search-for-case .js-related-case'),
  $searchOriginCaseButton: $('#xhr-search-original-case-button'),
  $searchRelatedCaseButton: $('#xhr-search-related-case-button'),

  originalCaseReport: document.querySelector('.js-original-case-report'),
  relatedCaseReport : document.querySelector('.js-related-case-report'),


  init: function () {
    var self = this;

    if(self.$deliveryMethod.length > 0) {
      self.showHideDeliveryMethodFields();

      //Bind events
      self.$deliveryMethod.on('change', ':radio', function () {
        self.showHideDeliveryMethodFields();
      });
    }

    if (self.originalCaseReport) {
      self.toggleFields(self);
    }

    // For linking to original case
    self.$searchOriginCaseButton.add(self.$searchRelatedCaseButton)
      .click(function (e) {
        e.preventDefault();

        self.getCaseDetails(this)
          .done(function(json) {
            self.removeErrorMessage();

            if (json.link_type === 'original') {

              // insert the original case report
              self.originalCaseReport.innerHTML = json.content;
              // Switch fields so user can type in related cases
              self.showRelatedCaseField(self);

            } else {

              self.relatedCaseReport.innerHTML = json.content;
              self.$relatedCaseInput.val('').focus();
            }
          })
          .fail(function(jqxhr){
            self.displayErrorMessage(jqxhr.responseJSON);
          });
      });

    self.$originalCaseInput.on('keypress', function(e){
      if (e.keyCode === 13 ) {
        e.preventDefault()
        $(self.$searchOriginCaseButton).trigger('click');
      }
    });

    self.$relatedCaseInput.on('keypress', function(e){
      if (e.keyCode === 13 ) {
        e.preventDefault()
        $(self.$searchRelatedCaseButton).trigger('click');
      }
    });

    // Undo actions
    $('.js-original-case-and-friends')
    .on('click','.js-remove-original', function (e) {
      self.removeOriginalCase(e,self);
    }).on('click', 'a.js-remove-related', function (e){
      self.removeOtherRelatedCase(e, self);
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

    var related_case_ids = $( moj.Modules.CaseCreation.relatedCaseReport)
                              .find(':hidden[name="case_ico[related_case_ids][]"]')
                              .map(function() { return this.value; })
                              .get()
                              .join(' ');

    return $.getJSON($(button).data('url'), {
          'original_case_number': document.getElementById('case_ico_original_case_number').value,
          'related_case_number' : document.getElementById('case_ico_related_case_number').value,
          'related_case_ids': related_case_ids,
          'correspondence_type': document.getElementById('correspondence_type').value,
          'link_type': $(button).data('link-type')
        });
  },

  removeOtherRelatedCase: function (event) {
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

  removeOriginalCase: function (event,self) {
    event.preventDefault();
    self.originalCaseReport.innerHTML = '';

    self.toggleFields(self);

    self.$originalCaseInput.focus();
  },

  showRelatedCaseField: function (self) {
    self.toggleFields(self);
    self.$relatedCaseInput.focus();
  },

  displayErrorMessage: function (errorObject) {
    var $searchForCase = $('#js-search-for-case');
    var $currentField = $searchForCase.find(':text:visible');
    var $formGroup = $currentField.closest('.form-group');

    // Add Red border
    $formGroup
      .addClass('form-group-error');

    // Find remove previous errors and then add new error
    $formGroup.find('label')
      .find('.error-message')
      .remove()
      .end()
      .append('<span class="error-message">' + errorObject.linked_case_error + '</span>');
  },

  removeErrorMessage: function () {
    var $searchForCase = $('#js-search-for-case');
    var $currentField = $searchForCase.find(':text:visible');
    var $formGroup = $currentField.closest('.form-group');

    // Add Red border
    $formGroup
      .removeClass('form-group-error');

    // Find remove previous errors and then add new error
    $formGroup.find('label')
      .find('.error-message')
      .remove();
  },

  toggleFields: function (self) {

    if (self.originalCaseReport.innerHTML === '') {

      self.$relatedCaseFields.addClass('js-hidden');
      self.$originalCaseFields.removeClass('js-hidden');

    } else {
      self.$relatedCaseFields.removeClass('js-hidden');
      self.$originalCaseFields.addClass('js-hidden');
    }
  }
};
