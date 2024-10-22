moj.Modules.ValidationEvent = {
  init: function() {
    window.onload = function() {
      window.dataLayer = window.dataLayer || [];

      if($('.form-group-error').size() > 0) {
        $('.form-group-error').each( function(_, obj) {
          window.dataLayer.push({
            event: "validation_error",
            fieldName: obj.getAttribute("id"),
            errorMessage: $(obj).find('.error-message').text()
          });
        });
      }
    }
  }
}
