require "./lib/translate_for_case"

# rubocop:disable Rails/HelperInstanceVariable
module CasesHelper
  def sort_correspondence_types_for_display(types)
    types_have_display_order = types.all? do |t|
      t.display_order.present?
    end

    types.sort_by!(&:display_order) if types_have_display_order
    types
  end

  def download_csv_link(full_path, csv_report = nil, download_link_name = nil)
    uri = URI(full_path)
    csv_path = "#{uri.path}.csv"
    queries = []
    if uri.query.present?
      queries << uri.query
    end
    if csv_report.present?
      queries << "report=#{csv_report}"
    end
    unless queries.empty?
      csv_path += "?#{queries.join('&')}"
    end
    link_to download_link_name || "Download cases", csv_path
  end

  def get_cases_order_option_url(original_uri, current_order_option)
    new_option = get_new_option(current_order_option)

    uri = URI.parse(original_uri)
    hash_params = Hash[URI.decode_www_form(uri.query || "")]
    hash_params["order"] = new_option
    uri.query = URI.encode_www_form(hash_params)
    link_to t("common.show_#{new_option}"), uri.to_s
  end

  def accepted_case_attachment_types
    Settings.case_uploads_accepted_types.join ","
  end

  def docx_content_type
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  end

  def case_link_with_hash(kase, field, page, position)
    span = content_tag(:span,
                       t("common.case_list.view_case"),
                       class: "visually-hidden")

    case_number = kase.__send__(field)

    page = 1 if page.blank?

    if position.nil?
      link_to span + case_number, case_path(kase.id)
    else
      position += 1
      page_offset = Kaminari.config.default_per_page * (page.to_i - 1)
      link_to span + case_number, case_path(kase.id, pos: page_offset + position)
    end
  end

  def action_button_for(event)
    case event
    # Offender SAR case state transitions e.g. mark as ready for vetting
    when /mark_as_([a-zA-Z]*)/
      link_text = t("event.#{event}")
      action_url = if @case.offender_sar?
                     transition_case_sar_offender_path(@case, event)
                   else
                     transition_case_sar_offender_complaint_path(@case, event)
                   end
      link_to link_text,
              action_url,
              id: "action--#{link_text.parameterize}",
              class: "button state-action-button",
              method: "patch"
    when :move_case_back
      link_to t("common.case/offender_sar.move_case_back"),
              move_case_back_case_sar_offender_path(@case),
              id: "action--move_case_back",
              class: "button state-action-button"
    when :record_further_action
      action_url = record_further_action_case_ico_path(@case)
      link_to t("common.case/ico_foi.record_further_action"),
              action_url,
              id: "action--record_further_action",
              class: "button state-action-button"
    when :capture_reason_for_lateness
      link_to t("common.case/offender_sar.record_reason_for_lateness"),
              record_reason_for_lateness_case_sar_offender_path(@case),
              id: "action--record_reason_for_lateness",
              class: "button state-action-button"
    when :start_complaint
      link_to I18n.t("common.case/offender_sar.start_complaint"),
              start_complaint_case_sar_offender_complaint_index_path(@case.number),
              id: "action--start-complaint",
              class: "button",
              method: "post"
    when :add_approval_flags_for_ico
      link_to I18n.t("common.case/offender_sar_complaint.add_approval_flags_for_ico"),
              edit_step_case_sar_offender_complaint_path(@case, "approval_flags"),
              id: "action--add_approval_flags_for_ico",
              class: "button"
    when :add_approval_flags_for_litigation
      link_to I18n.t("common.case/offender_sar_complaint.add_approval_flags_for_litigation"),
              edit_step_case_sar_offender_complaint_path(@case, "approval_flags"),
              id: "action--add_approval_flags_for_litigation",
              class: "button"
    when /add_complaint_([a-zA-Z]*)/
      page_name = event.to_s.gsub("add_complaint_", "")
      link_to I18n.t("common.case/offender_sar_complaint.#{event}"),
              edit_step_case_sar_offender_complaint_path(@case, page_name),
              id: "action--add_complaint_#{page_name}",
              class: "button"
    when :assign_responder
      link_to I18n.t("common.case.assign"),
              new_case_assignment_path(@case),
              id: "action--assign-to-responder",
              class: "button"
    when :move_to_team_member
      action_url = if @case.current_state == "ready_for_vetting"
                     assign_to_vetter_case_assignments_path(@case)
                   else
                     assign_to_team_member_case_assignments_path(@case)
                   end
      link_to I18n.t("common.case/#{@case.type_abbreviation.downcase}.assign"),
              action_url,
              id: "action--assign-to-team-member",
              class: "button"
    when :assign_to_new_team
      link_to "Assign to another team",
              assign_to_new_team_case_assignment_path(@case, @case.responder_assignment),
              id: "action--assign-new-team",
              class: "button-secondary"
    when :add_responses
      link_to t("common.case.upload_response"),
              new_case_responses_path(@case, response_action: :upload_responses),
              id: "action--upload-response",
              class: "button"
    when :create_overturned
      action_url = @case.original_case_type == "FOI" ? new_case_overturned_ico_fois_path(@case) : new_case_overturned_ico_sars_path(@case)
      link_to t("common.case.create_overturned"),
              action_url,
              id: "action--create-overturned",
              class: "button"
    when :respond
      link_to translate_for_case(@case, "common", "respond"),
              polymorphic_path(@case, action: :respond),
              id: "action--mark-response-as-sent",
              class: "button"
    when :reassign_user
      return "" if @assignments.blank?

      action_url = if @assignments.size > 1
                     select_team_case_assignments_path(@case, assignment_ids: @assignments.map(&:id).join("+"))
                   else
                     reassign_user_case_assignment_path(@case, @assignments.first)
                   end
      link_to t("common.case.reassign_case"),
              action_url,
              id: "action--reassign-case",
              class: "button"
    when :approve
      link_to t("common.case.clear_response"),
              new_case_approval_path(@case),
              id: "action--approve",
              class: "button"
    when :request_amends
      link_to t("common.case.request_amends"),
              new_case_amendment_path(@case),
              id: "action--request-amends",
              class: "button"
    when :upload_response_and_approve
      link_to t("common.case.upload_approve"),
              new_case_responses_path(@case, response_action: :upload_response_and_approve),
              id: "action--upload-approve",
              class: "button"
    when :upload_response_and_return_for_redraft
      link_to t("common.case.upload_and_redraft"),
              new_case_responses_path(@case, response_action: :upload_response_and_return_for_redraft),
              id: "action--upload-redraft",
              class: "button"
    when :close, :respond_and_close
      link_to translate_for_case(@case, "common", "close"),
              polymorphic_path(@case, action: :close),
              id: "action--close-case",
              class: "button", method: :get
    when :send_back
      link_to I18n.t("event.#{event}"),
              send_back_case_foi_path(@case),
              id: "action--send-back",
              class: "button"
    when :progress_for_clearance
      link_to I18n.t("common.case.progress_for_clearance"),
              progress_for_clearance_case_path(@case),
              id: "action--progress-for-clearance",
              class: "button", method: :patch
    when :extend_sar_deadline
      link_to I18n.t("common.case.extend_sar_deadline"),
              new_case_sar_extension_path(@case),
              id: "action--extend-deadline-for-sar",
              class: "button-secondary"
    when :remove_sar_deadline_extension
      link_to I18n.t("common.case.remove_sar_deadline_extension"),
              case_sar_extensions_path(@case),
              id: "action--remove-extended-deadline-for-sar",
              class: "button-secondary", method: :delete
    when :record_data_request_area
      link_to "Record data request",
              new_case_data_request_area_path(@case),
              id: "action--record-data-request-area",
              class: "button-tertiary"
    when :record_data_request
      link_to "Add data request type",
              new_case_data_request_area_data_request_path(@case, @data_request_area),
              id: "action--record-data-request-type",
              class: "button"
    when :upload_request_files
      link_to "Upload request files",
              new_case_attachment_path(@case),
              id: "action--upload-request-files",
              class: "button-tertiary"
    when :send_acknowledgement_letter
      link_to "Send acknowledgement letter",
              new_case_letters_path(@case.id, "acknowledgement"),
              id: "action--send-acknowledgement-letter",
              class: "button-secondary"
    when :send_dispatch_letter
      link_to "Send dispatch letter",
              new_case_letters_path(@case.id, "dispatch"),
              id: "action--send-dispatch-letter",
              class: "button-secondary"
    when :record_sent_to_sscl
      return if @case.sent_to_sscl_at.present?

      link_to "Sent to SSCL",
              edit_step_case_sar_offender_path(@case, "sent_to_sscl"),
              id: "action--send-sent-to-sscl",
              class: "button-secondary"
    when :preview_cover_page
      link_to "Preview cover page",
              case_cover_page_path(@case),
              id: "action--preview-cover-page",
              class: "button-secondary"
    when :accepted_date_received
      link_to "Create valid case",
              confirm_accepted_date_received_case_sar_offender_path(@case),
              id: "action--accepted-date-received",
              class: "button"
    when :stop_the_clock
      link_to t("common.case.stop_the_clock"),
              new_case_stop_the_clock_path(@case),
              id: "action--stop_the_clock",
              class: "button state-action-button"
    end
  end

  def show_hide_message(kase)
    (preview_copy, remaining_copy) = kase.message_extract

    if remaining_copy.nil?
      kase.message
    else
      content_tag(:span, preview_copy, class: "ellipsis-preview") +
        content_tag(:span, "...", class: "ellipsis-delimiter js-hidden") +
        content_tag(:span, remaining_copy, class: "ellipsis-complete js-hidden") +
        link_to("Show more", "#", class: "ellipsis-button js-hidden")
    end
  end

  def attachment_download_link(kase, attachment)
    link_to t("common.case.download_link_html", filename: attachment.filename),
            download_case_attachment_path(kase, attachment),
            class: "download"
  end

  def show_remove_clearance_link(kase)
    if policy(kase).remove_clearance?
      link_to("Remove clearance", remove_clearance_case_path(kase))
    end
  end

  def attachment_preview_link(attachment)
    if !attachment.preview_key.nil?
      link_to "View",
              case_attachment_path(attachment.case, attachment),
              { target: "_blank", class: "view", rel: "noopener" }
    else
      ""
    end
  end

  def attachment_remove_link(kase, attachment)
    link_to t("common.case.remove_link_html", filename: attachment.filename),
            case_attachment_path(kase, attachment),
            { method: :delete,
              class: "delete",
              remote: true,
              data: {
                confirm: "Are you sure you want to remove #{attachment.filename}?",
              } }
  end

  def exemptions_checkbox_selector(exemption, kase)
    if kase.exemptions.map(&:id).include?(exemption.id)
      "selected"
    else
      ""
    end
  end

  def case_attachments_visible_for_case?(kase)
    return false if kase.attachments.response.blank?

    policy(kase).can_view_attachments?
  end

  def case_uploaded_request_files_class
    "error" if @case.errors.include? :uploaded_request_files
  end

  def case_uploaded_request_files_id
    if @case.errors.include? :uploaded_request_files
      "error_case_uploaded_request_files"
    end
  end

  def action_links_for_allowed_events(kase, *events)
    allowed_events = events.find_all do |event_name|
      policy(kase).__send__ "#{event_name}?"
    end
    allowed_events.map do |event_name|
      __send__ "action_link_for_#{event_name}", kase
    end
  end

  def action_buttons_for_allowed_events(kase, *events)
    events
      .find_all { |name| policy(kase).send("#{name}?") }
      .map { |name| send("action_button_for_#{name}", kase) }
  end

  def action_link_for_destroy_case(kase)
    link_to "Delete case", confirm_destroy_case_path(kase)
  end

  def action_button_for_destroy_case(kase)
    link_to "Delete case",
            confirm_destroy_case_path(kase),
            class: "button-secondary"
  end

  def action_button_for_extend_for_pit(kase)
    link_to I18n.t("common.case.extend_for_pit"),
            new_case_pit_extension_path(kase),
            id: "action--extend-for-pit",
            class: "button-secondary"
  end

  def action_button_for_remove_pit_extension(kase)
    link_to I18n.t("common.case.remove_pit_extension"),
            case_pit_extensions_path(kase),
            id: "action--remove-pit-extension",
            method: :delete,
            class: "button-secondary"
  end

  def action_link_for_new_case_link(kase)
    link_to "Link a case",
            new_case_link_path(kase.id),
            class: "secondary-action-link",
            id: "action--link-a-case"
  end

  def action_link_for_destroy_case_link(kase, linked_case)
    if policy(kase).destroy_case_link?
      link_to t("common.case.remove_linked_case_html", case_number: linked_case.number),
              case_link_path(case_id: kase.id, id: linked_case.number),
              data: { confirm: "Are you sure?" },
              method: :delete
    end
  end

  def request_details_html(kase)
    content_tag(:strong, "#{kase.subject} ", class: "strong") +
      if kase.type == "Case::SAR::Offender"
        if kase.third_party? && kase.third_party_company_name.present?
          content_tag(:div, kase.third_party_company_name, class: "data-detail")
        elsif kase.third_party? && kase.third_party_company_name.blank?
          content_tag(:div, kase.third_party_name, class: "data-detail")
        else
          content_tag(:div, kase.subject, class: "data-detail")
        end
      else
        content_tag(:div, kase.name, class: "data-detail")
      end
  end

  # Note exceptions for FOI sub-classes because REST routes for FOI
  # sub-classes do not exist (adds more complexity than needed)
  def case_details_links(kase, user)
    links = ""

    if kase.allow_event?(user, :edit_case)
      links << link_to(t("helpers.links.case_details.edit_case"),
                       kase.foi? ? edit_case_foi_standard_path(kase) : edit_polymorphic_path(kase),
                       class: "secondary-action-link")
    end

    if kase.allow_event?(user, :update_closure)
      links << link_to(t("helpers.links.case_details.edit_closure"),
                       kase.foi? ? edit_closure_case_foi_standard_path(kase) : polymorphic_path(kase, action: :edit_closure),
                       class: "secondary-action-link")
    end
    links
  end

  def translate_for_case(*args, **options)
    options[:translator] ||= public_method(:t)
    TranslateForCase.translate(*args, **options)
  end
  alias_method :t4c, :translate_for_case

  def case_details_for_link_type(link_type)
    if link_type.present?
      "#{link_type}-case-details"
    else
      "case-details"
    end
  end

  def manager_updating_close_details_on_old_case?(user, kase)
    # the only reason a manager can't the closure details of a closed case is because
    # it is an "old style" closure, i.e. it was closed before we implemented the new
    # outcomes, info_held statuses, refusal reasons, etc
    user.manager? && kase.closed? && !kase.allow_event?(user, :update_closure)
  end

  # Note use of Case::FOI::Standard for Timeliness/ComplianceReview FOI cases
  def case_create_action(kase)
    if kase.foi?
      send("case_foi_standard_index_path")
    else
      send("#{kase.model_name.singular}_index_path")
    end
  end

  def show_escalation_deadline?(kase)
    !kase.type_of_offender_sar? &&
      kase.has_attribute?(:escalation_deadline) &&
      kase.within_escalation_deadline?
  end

  def get_sar_recipient_label(recipient)
    case recipient
    when "requester_recipient"
      t("helpers.label.offender_sar.recipient_type.recipient")
    when "subject_recipient"
      t("helpers.label.offender_sar.recipient_type.data_subject")
    else
      t("helpers.label.offender_sar.recipient_type.third_party")
    end
  end

  def choose_cover_page_id_number(prison_number, pnc_number)
    prison_number = get_first_number_in_string(prison_number)
    pnc_number = get_first_number_in_string(pnc_number)

    return pnc_number if prison_number.nil?
    return pnc_number if prison_number.empty?

    prison_number
  end

private

  def get_first_number_in_string(number_string)
    return number_string.split(",").first&.upcase if number_string&.include?(",")

    number_string&.upcase
  end

  def get_new_option(current_order_option)
    default_oldest = "search_result_order_by_oldest_first"
    default_newest = "search_result_order_by_newest_first"
    destruction_oldest = "search_result_order_by_oldest_destruction_date"
    destruction_newest = "search_result_order_by_newest_destruction_date"

    if current_order_option == destruction_newest
      destruction_oldest
    elsif current_order_option == destruction_oldest
      destruction_newest
    elsif current_order_option == default_newest
      default_oldest
    elsif current_order_option == default_oldest
      default_newest
    else
      default_newest
    end
  end
end
# rubocop:enable Rails/HelperInstanceVariable
