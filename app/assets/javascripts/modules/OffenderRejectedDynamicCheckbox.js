// Offender SAR rejected cases form
// Provides a dynamic text_area which displays when the user chooses the 'other' checkbox

const other_checkbox = document.getElementById('offender_sar_rejected_reasons_other');
const text_area = document.querySelector('.display-none #offender_sar_other_rejected_reason');
const text_area_parent_div = text_area.closest('.display-none');
other_checkbox.addEventListener('click', function() {
  if (other_checkbox.checked) {
    text_area_parent_div.classList.remove("display-none")
  } else {
    text_area_parent_div.classList.add("display-none")
  }
})
