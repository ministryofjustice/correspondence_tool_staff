describe('Modules.AssignmentEdit.js', function() {
  it('should exist with expected constructures', function() {
    expect(moj.Modules.AssignmentEdit.init).toBeDefined();
    expect(moj.Modules.AssignmentEdit.showHideRejectionFields).toBeDefined();
  });


  describe('Methods', function() {
    describe('...init', function() {

      beforeEach(function() {
        spyOn(moj.Modules.AssignmentEdit, 'showHideRejectionFields');
      });

      it('should default show/hide Rejection Reasons', function() {
        moj.Modules.AssignmentEdit.init();
        expect(moj.Modules.AssignmentEdit.showHideRejectionFields).toHaveBeenCalled();
      });
    })
  })
});
