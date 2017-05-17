moj.Modules.CaseClosure = {
    init: function () {
        $('.js-de-escalate-link').on('click', function(e) {
            var $link = $(this)[0];
            $.ajax({
                url: $link.href,
                method: 'patch',
                statusCode: {
                    204: function() {
                        $td = $($link.closest('td'));
                        $td.find('.escalated-container').hide();
                        $td.find('.de-escalated-container').show();
                    }
                }
            });
            return false;
        });
   }
};
