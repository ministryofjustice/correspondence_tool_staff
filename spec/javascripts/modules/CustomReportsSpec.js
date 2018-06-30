describe('Modules.CustomReports.js', function() {
  it('should exist with expected constructures', function() {
    expect(moj.Modules.CustomReports.init).toBeDefined();
    expect(moj.Modules.CustomReports.showHideReportsTypes).toBeDefined();
  });

  describe('Methods', function() {
    describe('...init', function() {

      beforeEach(function() {
        spyOn(moj.Modules.CustomReports, 'showHideReportsTypes');
      });

      it('should default show/hide FOI/SAR Reports', function() {
        moj.Modules.CustomReports.init();
        expect(moj.Modules.CustomReports.showHideReportsTypes).toHaveBeenCalled();
      });
    })
  })
});
