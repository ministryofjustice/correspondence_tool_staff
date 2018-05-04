moj.Modules.AssignedToFilter = {

    init: function () {

      var module = this;

      $('#search_query_business_unit_name_filter').on('keyup', function(){
        if(this.value !== '') {
          $('.js-all-business-units').show();
          module.getMatchingBusinessUnits(this.value);
        } else {
          $('.js-all-business-units, .js-no-results').hide();

        }
      }).trigger('keyup')
    },


    getMatchingBusinessUnits: function (searchFor) {
      $('.js-all-business-units').find('.multiple-choice')
      .each(function (index, element) {
        var $elem = $(this);
        // Remove any character that is not alphanumeric
        var labelText = $elem.text().replace(/[^a-z0-9+]+/gi, '');
        // Remove any character that is not alphanumeric
        var cleanedTerm = searchFor.replace(/[^a-z0-9+]+/gi, '');
        var check = new RegExp(cleanedTerm, 'gi');


        // if checkbox label test contains any part of the search term
        if (check.test(labelText)) {
          $elem.show();
        } else {
          $elem.hide();
          $elem.find(':checkbox').prop('checked', false);
        }
      });

      if ($('.js-all-business-units').find('.multiple-choice').filter(':visible').length > 0){
        $('.js-no-results').hide();
      } else {
        $('.js-no-results').show();
        $('.js-all-business-units').hide();
      }
    }

}
