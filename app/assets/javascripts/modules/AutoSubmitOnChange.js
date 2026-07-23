// Auto-submits the containing form when a select with the
// `js-auto-submit` class changes. Replaces inline `onchange`
// handlers, which are blocked by the Content Security Policy.
moj.Modules.AutoSubmitOnChange = {
  init: function () {
    $('body').on('change', 'select.js-auto-submit', function () {
      this.form.submit();
    });
  }
}