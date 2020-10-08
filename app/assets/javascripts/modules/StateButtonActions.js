moj.Modules.StateButtonActions = {
  init: function() {

    function do_nothing() { 
      return false;
    }
    // This function is to prevent user from double clicking the state action button
    $('.state-action-button').on('click', function(e) { 
      $(e.target).click(do_nothing); 
      setTimeout(function(){
        $(e.target).unbind('click', do_nothing);
      }, 10000); 
    });
  }
};
