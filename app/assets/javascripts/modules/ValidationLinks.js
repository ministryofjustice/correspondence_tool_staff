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

		// Check if it's possible to get a link prefix
		this.getCommonHrefPrefixFromLinks();
		if(!this.linkPrefix) return;

		// Update all links to work if possible and needed
		this.checkAndUpdateAllLinks();
	},
	removeAnyExtraSummaries: function() {
		if(this.$errorSummary.length > 1) {
			this.$errorSummary.first().remove();
		}
	},
	matchSingleDivLinks: function() {
		var LinkHrefId = this.$allValidationDivs[0].id;
		this.$allValidationLinks.each(function(){
			$(this).attr('href', '#' + LinkHrefId);
		});
	},
	getCommonHrefPrefixFromLinks: function() {
		var arr = [];
		this.$allValidationLinks.each(function(ind, el) {
			arr.push(el.href ? el.href.split('#')[1] : '');
		});
		var A = arr.concat().sort(), 
    a1 = A[0], a2 = A[A.length-1], L = a1.length, i = 0;
    while(i<L && a1.charAt(i) === a2.charAt(i)) i++;
    this.linkPrefix = a1.substring(0, i);
	},
	checkAndUpdateAllLinks: function(){
		var that = this;
		this.$allValidationLinks.each(function(ind) {
			var fieldId = $(this).attr('href').split(that.linkPrefix)[1];
			if(!fieldId) return; 
			if($('#' + that.linkPrefix + fieldId).length > 0) return; // link already working
			that.updateLinkToMatchDiv($(this), fieldId);
		});
	},
	updateLinkToMatchDiv: function($link, fieldId) {
		this.$allValidationDivs.each(function(span){
			str = $(this).attr('id');
			if(str.indexOf(fieldId)>-1) {
				$link.attr('href', '#' + str);
			}
		});
	}	
}