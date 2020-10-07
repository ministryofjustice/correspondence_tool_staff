moj.Modules.StateButtonActions = {
  init: function() {

    function do_nothing() { 
      return false;
    }
    $('.state-action-button').on('click', function(e) { 
      $(e.target).click(do_nothing); 
      setTimeout(function(){
        $(e.target).unbind('click', do_nothing);
      }, 10000); 
    });
  }
};
