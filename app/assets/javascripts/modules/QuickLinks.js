moj.Modules.QuickLinks = {
  init: function (){
    var $quickLinks = $('.quick-link-option--first, .quick-link-option');
     this.bindFinalDeadlineEvents($quickLinks);
  },

  bindFinalDeadlineEvents: function($quickLinks){
    $quickLinks.on('click', 'a', function(event){
      var $elem = $(this);
      var objFromData = $elem.data('external-deadline-from');
      var objToData = $elem.data('external-deadline-to');
      var fieldsIDprefix = 'search_query_external_deadline';
      var $parentForm = $elem.closest('form');

      $('#' + fieldsIDprefix + '_from_dd').val(objFromData.day);
      $('#' + fieldsIDprefix + '_from_mm').val(objFromData.month);
      $('#' + fieldsIDprefix + '_from_yyyy').val(objFromData.year);

      $('#' + fieldsIDprefix + '_to_dd').val(objToData.day);
      $('#' + fieldsIDprefix + '_to_mm').val(objToData.month);
      $('#' + fieldsIDprefix + '_to_yyyy').val(objToData.year);
      $parentForm.find('input[type="submit"]').focus();
      event.preventDefault();
    })
  }
}
