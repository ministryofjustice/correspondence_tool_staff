moj.Modules.ExemptionFilter = {
  init: function() {
    $('.exemption-most-used').on('click', ':checkbox', function(){
      var $elem = $(this);
      $('.exemption-all label[for="search_query_exemption_' + $elem.val() + '"]').click();
    })

    $('.exemption-all').on('click', ':checkbox', function(){
      var $elem = $(this);
      $('.exemption-most-used label[for="search_query_most_frequently_used_' + $elem.val() + '"]').click();
    })
  }
}
