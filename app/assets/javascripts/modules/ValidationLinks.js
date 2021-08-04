// This is to fix the mismatch between the prefixes for validation # links that break after
// we re-use ruby code. i.e. when we use "as ..." in form generation, context breaks links
moj.Modules.ixValidationLinks = {
	$errorSummary: $('.error-summary'),
	$allValidationLinks: $('.error-summary-list a'),
	$allValidationDivs: $('.form-group-error'),
	$linkPrefix: null,
	
	init: function() {
		if(this.$allValidationLinks.length === 0) return; // Don't bother if no error on page

		this.removeAnyExtraSummaries(); // sometimes it shows two summaries, remove redundant one
	},
	removeAnyExtraSummaries: function() {
		if(this.$errorSummary.length > 1) {
			this.$errorSummary.first().remove();
		}
	}
}