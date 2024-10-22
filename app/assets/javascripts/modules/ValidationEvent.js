moj.Modules.ValidationEvent = {
  init: function() {
    window.onload = function() {
      window.dataLayer = window.dataLayer || [];

      if($('.error-message').size() > 0) {
        $('.error-message').each( function(_, obj) {
          window.dataLayer.push({
            event: "validation_error",
            fieldName: obj.getAttribute("id"),
            errorMessage: obj.textContent
          });
        });
      }
    }
  }
}
