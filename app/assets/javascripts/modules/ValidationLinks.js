// This is to fix the mismatch between the prefixes for validation # links that break after
// we re-use ruby code. i.e. when we use "as ..." in form generation, context breaks links
moj.Modules.fixValidationLinks = {
	$errorSummary: $('.error-summary'),
	$allValidationLinks: $('.error-summary-list a'),
	$allValidationDivs: $('.form-group-error'),
	$linkPrefix: null,
	
	init: function() {
		if(this.$allValidationLinks.length === 0) return; // Don't bother if no error on page

		this.removeAnyExtraSummaries(); // sometimes it shows two summaries, remove redundant one

		// If there's just one validation div, just make all links go to it..
		if(this.$allValidationDivs.length === 1 && this.$allValidationLinks.length > 0) { 
			this.matchSingleDivLinks();
			return;
		}
	},
	removeAnyExtraSummaries: function() {
		if(this.$errorSummary.length > 1) {
			this.$errorSummary.first().remove();
		}
	},
	matchSingleDivLinks: function() {

	}
}