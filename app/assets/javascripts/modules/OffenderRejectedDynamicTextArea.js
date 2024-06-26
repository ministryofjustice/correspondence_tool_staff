moj.Modules.OffenderRejectedDynamicTextArea = {
  // Offender SAR reason-rejected cases partial
  // Provides a dynamic text_area which displays when the user chooses the 'other' checkbox
  init: function () {
    var other_checkbox = document.getElementById('offender_sar_rejected_reasons_other');
    var text_area = document.getElementById('other-text-area-container');

    if (!other_checkbox) return;

    other_checkbox.addEventListener('click', function () {
      if (other_checkbox.checked) {
        text_area.classList.remove("display-none");
      } else {
        text_area.classList.add("display-none");
      }
    })

    // Replaces the forms legend class styling to match form-hint
    // as collection_check_boxes requires a legend and form-hint.
    var form_label = document.querySelectorAll("span.form-label-bold");
    form_label[0].classList.replace("form-label-bold", "form-hint");

    // Adds a vertical grey bar to the left of the text_area form-group
    text_area.classList.add("panel", "panel-border-narrow");
  }
};
