class ContactsController < ApplicationController
  before_action :set_contact, only: %i[edit update destroy]
  before_action :set_new_contact_from_params, only: :create
  before_action :set_contact_type, only: :create

  def new
    @contact_types = CategoryReference.list_by_category(:contact_type)

    @contact_type = ContactType.new
  end

  def new_details
    @contact_type = ContactType.new(contact_type_params)
    if @contact_type.valid?
      @contact = Contact.new(contact_type_id: @contact_type.contact_type_id)
    else
      @contact_types = CategoryReference.list_by_category(:contact_type)
      render :new
    end
  end

  def index
    @contacts = Contact.includes([:contact_type]).order(:name).decorate
  end

  def edit; end

  def create
    respond_to do |format|
      if @contact.save
        format.html { redirect_to contacts_url, notice: "Contact was successfully created." }
      else
        format.html { render :new_details, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @contact.update(contact_params)
        format.html { redirect_to contacts_url, notice: "Address was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @contact.destroy # rubocop:disable Rails/SaveBang
    respond_to do |format|
      format.html { redirect_to contacts_url, notice: "Address was successfully destroyed." }
    end
  rescue ActiveRecord::InvalidForeignKey
    flash[:alert] = t("common.contacts.delete_error")
    redirect_to contacts_path
  end

  def contacts_search
    search_term = contacts_search_param[:contacts_search_value]&.downcase

    filters = params[:search_filters]&.split(",")

    @contacts = ContactsSearchService.new(filters:, search_term:).call

    render :contacts_search, layout: nil
  end

private

  def set_contact
    @contact = Contact.includes(:contact_type).find(params[:id])
  end

  def set_new_contact_from_params
    @contact = Contact.new(contact_params)
  end

  def set_contact_type
    if contact_params[:contact_type_id]
      @contact_type = CategoryReference.find(contact_params[:contact_type_id])
      @contact.contact_type = @contact_type
    else
      @contact.contact_type = nil
    end
  end

  def contact_params
    params.require(:contact).permit(
      :name,
      :address_line_1,
      :address_line_2,
      :town,
      :county,
      :postcode,
      :data_request_name,
      :data_request_emails,
      :contact_type_id,
    )
  end

  def contact_type_params
    params.require(:contact_type).permit(
      :contact_type_id,
    )
  end

  def contacts_search_param
    params.permit(:contacts_search_value)
  end
end
