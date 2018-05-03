moj.Modules.AssignedToFilter = {

    init: function () {

      var module = this;

      $('#search_query_business_unit_name_filter').on('keyup', function(){
        if(this.value !== '') {
          $('.js-all-business-units').show();
          module.getMatchingBusinessUnits(this.value);
        } else {
          $('.js-all-business-units').hide();
        }
      }).trigger('keyup')
    },


    getMatchingBusinessUnits: function (searchFor){
      $('.js-all-business-units').find('.multiple-choice')
        .each(function( index, element ) {
          var $elem = $(this);
          // Remove any character that is not alphanumeric
          var labelText = $elem.text().replace(/[^a-z0-9+]+/gi, '');
          // Remove any character that is not alphanumeric
          var cleanedTerm = searchFor.replace(/[^a-z0-9+]+/gi, '');

          // if checkbox label test contains any part of the search term
          if (labelText.search(cleanedTerm, 'gi') > -1){
              $elem.show();
          }else{
              $elem.hide();
              $elem.find(':checkbox').prop('checked', false);
          }
        })
    }

}
