moj.Modules.CaseClosure = {
  init: function () {
    function toggleEscalatedContainers() {
      var $link = $(this);
      $.ajax({
        url: $link.attr('href'),
        method: 'patch',
        statusCode: {
          204: function() {
            var $td = $link.closest('td');
            $td.find('.escalated-container').toggle();
            $td.find('.de-escalated-container').toggle();
          }
        }
      });
      return false;
    }

    $('.js-de-escalate-link, .js-undo-de-escalate-link').on(
      'click', toggleEscalatedContainers
    );
  }
};
