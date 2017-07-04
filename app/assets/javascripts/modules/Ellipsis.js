moj.Modules.Ellipsis = {
  init: function() {

    $('.ellipsis-delimiter, .ellipsis-button').removeClass('js-hidden');
    $('.ellipsis-button').on('click', function(e) {
      var $button = $(this);
      var $parent = $button.parent();
      var $delimiter = $parent.find('.ellipsis-delimiter');
      var $longMessage = $parent.find('.ellipsis-complete');

      $longMessage.toggleClass('js-hidden');
      $delimiter.toggleClass('js-hidden');

      if ($button.text() == 'Show more') {
        $button.text('Show less');
      } else {
        $button.text('Show more');
      }

      e.preventDefault();
    });
  }
};
