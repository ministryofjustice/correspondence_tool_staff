var Dropzone;

moj.Modules.Dropzone = {
  $target: {},
  init : function() {
    var self = this;

    this.$target = $('.dropzone');

    Dropzone.autoDiscover = false;

    this.$target.dropzone({
      url: this.$target.data('url'),
      method: 'post',
      addRemoveLinks: true,
      maxFilesize: 20,
      previewTemplate: this.$target.data('dz-template'),
      paramName: 'file',
      createImageThumbnails: false,
      acceptedFiles: this.$target.data('accepted-files'),
      dataType: 'XML',
      headers: { formData: this.$target.data('form-data')},
      sending: function(file, xhr, formData) {
        var s3Data = $(this.element).data('form-data');
        for(var k in s3Data) {
          if( s3Data.hasOwnProperty(k) ){
            formData.append( k , s3Data[k]);
          }
        }

      },
      success: function (file, response) {

        // extract key and generate URL from response
        var responseDoc = $.parseXML(response);
        var $response   = $(responseDoc);
        var key = $response.find('Key').text();
        var host = $(this.element).data('host');

        file.previewElement.classList.add('dz-success');

        if(file.accepted) {
          $(file.previewElement).find('.dz-upload').css('width', '100%');
        }

        // create hidden field
        var input = $('<input />', { class: 'case-uploaded-files'
                      , type:'hidden'
                      , name: 'uploaded_files[]'
                      , value: key });
        $(file.previewElement).append(input);

      },
      removedfile: function(file) {
        // server-side will take care of cleaning up uploads dir
        $(file.previewElement).remove();
      }
    });
  },
  createDocumentIdInput : function(id) {
    var input = '<input id="claim_document_ids_' + id + '" name="claim[document_ids][]" type="hidden" value="' + id + '">';
    this.$document_ids.append(input);
  },
  removeDocumentIdInput : function(id) {
    $('#claim_document_ids_' + id).remove();
  }
};

moj.Modules.ExternalLinks = {
  init: function(){
    $('[rel="external"]').is(function(id, el){
      $(el).append('<span class="visuallyhidden">opens in new window</span>');
    });
  }
};
