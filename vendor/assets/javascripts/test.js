(function(){
  'use strict';

  var moj = {

    // safe logging
    log: function (msg) {
      if (window && window.console) {
        window.console.log(msg);
      }
    },


  };

  window.testMoj = moj;
}());
