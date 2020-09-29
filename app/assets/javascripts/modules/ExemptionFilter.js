moj.Modules.ExemptionFilter = {
  init: function() {

    $('#common_exemption_ids_group').on('click', ':checkbox', function(){
      var $elem = $(this);
      var $allExemptionCheckbox = $('#search_query_exemption_ids_' + $elem.val());

      if ($elem.is(':checked')) {
        $allExemptionCheckbox.prop('checked',true)
      } else {
        $allExemptionCheckbox.prop('checked', false)
      }
    });

    $('#exemption_ids_group').on('click', ':checkbox', function(){
      var $elem = $(this);
      var $commonUsedCheckbox = $('#search_query_common_exemption_ids_' + $elem.val());

      if ($elem.is(':checked')) {
        $commonUsedCheckbox.prop('checked',true);
      } else {
        $commonUsedCheckbox.prop('checked', false);
      }
    })
  }
};
