moj.Modules.DataRequest = {
  $addMoreAction : $('.js-add-data-request'),

  init: function () {
    var self = this;
    self.$addMoreAction.removeClass('display-none');

    self.$addMoreAction.on('click', function(e){
      self.addDataRequest(e);
    });
  },

  addDataRequest: function (e){
    e.preventDefault();

    var $lastForm = $('.js-data-request__form').last();
    var $formTemplate = $lastForm.clone();
    var currentIndex = $formTemplate.data('index');
    var newIndex = currentIndex + 1;

    // Update new template with new index.
    // Brute force replace as there is no templating system.
    $formTemplate.attr('data-index', newIndex);
    $('.js-data-request__number', $formTemplate).first().text(newIndex + 1);
    $('.js-data-request__location', $formTemplate)[0].value = '';
    $('.js-data-request__data', $formTemplate)[0].value = '';

    $('.form-control', $formTemplate).each(function rename() {
      this.name = this.name.replace(currentIndex, newIndex);
      this.id = this.id.replace(currentIndex, newIndex);
    });

    $('.form-label', $formTemplate).each(function rename() {
      this.htmlFor = this.htmlFor.replace(currentIndex, newIndex);
    });

    $lastForm.after($formTemplate);
  },
};
