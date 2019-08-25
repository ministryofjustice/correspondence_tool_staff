module DataRequestsHelper
  def data_request_edit_action(kase, data_request)
    link_name =
      if data_request.num_pages > 0
        t('cases.data_requests.show.link_update')
      else
        t('cases.data_requests.show.link_mark')
      end

    link_to link_name, edit_case_data_request_path(kase, data_request)
  end
end
