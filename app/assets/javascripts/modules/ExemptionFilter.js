moj.Modules.ExemptionFilter = {
    init: function() {
        $('.exemption-most-used').on('click', ':checkbox', function(){
            var $elem = $(this);
            var $allExemptionCheckbox = $('.exemption-all #search_query_exemption_ids_' + $elem.val());

            if ($elem.is(':checked')) {
                $allExemptionCheckbox.prop('checked',true)
            } else {
                $allExemptionCheckbox.prop('checked', false)
            }
        });

        $('.exemption-all').on('click', ':checkbox', function(){
            var $elem = $(this);
            var $commonUsedCheckbox = $('.exemption-most-used #search_query_common_exemption_ids_' + $elem.val());

            if ($elem.is(':checked')) {
                $commonUsedCheckbox.prop('checked',true)
            } else {
                $commonUsedCheckbox.prop('checked', false)
            }
        })
    }
};
