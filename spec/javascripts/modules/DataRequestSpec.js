describe('Modules.DataRequest.js', function() {
  it('should exist with expected functions', function() {
    expect(moj.Modules.DataRequest.init).toBeDefined();
    expect(moj.Modules.DataRequest.addDataRequest).toBeDefined();
  });

  describe('Methods', function() {
    describe('...init', function() {
      it('should attach a click event to add more action', function() {
        var spyEvent = spyOnEvent('.js-add-data-request', 'click' );
        moj.Modules.DataRequest.init();

        Array.from(document.getElementsByClassName('js-add-data-request')).forEach(e => e.click());
        expect( spyEvent ).toHaveBeenTriggered();
        expect(moj.Modules.CaseBypass.addDataRequest).toHaveBeenCalled();
      });
    })
  })
});
