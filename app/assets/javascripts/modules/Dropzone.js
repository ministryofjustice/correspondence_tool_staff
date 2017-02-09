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
      /*init: function() {
        var thisDropzone = this;

        $.getJSON('/documents/?form_id=' + $('#claim_form_id').val()).done(function (data) {
          if(data) {
            $.each(data, function(index, item) {
              var existingFile = {
                name: item.document_file_name,
                size: parseInt(item.document_file_size),
                accepted: true
              };
              thisDropzone.emit('addedfile', existingFile);
              thisDropzone.emit('success', existingFile, { document : item });
              thisDropzone.emit('complete', existingFile);
            });
          }
        });
      },*/
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
        var url   = 'https://' + host + '/' + key;

       /* var id = response.document.id;
        $(file.previewTemplate).find('.dz-remove').attr('id', id);
        */
        file.previewElement.classList.add('dz-success');

        if(file.accepted) {
          $(file.previewElement).find('.dz-upload').css('width', '100%');
        }

        // create hidden field
        var input = $('<input />', { class: 'case-attachment-url'
                      , type:'hidden'
                      , name: 'attachment_url[]'
                      , value: url });

        $(this.element).closest('form').append(input);

      },
      removedfile: function(file) {
        var id = $(file.previewTemplate).find('.dz-remove').attr('id');

        if(id) {
          $.ajax({
            type: 'DELETE',
            url: '/documents/' + id,
            success : function(data) {
              $(file.previewElement).remove();
              self.removeDocumentIdInput(data.document.id);
            }
          });

          $(file.previewElement).remove();
        }
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
