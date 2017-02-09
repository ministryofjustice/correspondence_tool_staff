moj.Modules.Feedback = {
  init: function(){
    $('#new_feedback').on('ajax:success', function( e, data, status, xhr ){
      console.log(e);
      $(this).find('textarea').val('');
    });
  }
}
