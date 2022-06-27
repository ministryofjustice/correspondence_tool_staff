class ContactsController < ApplicationController
  before_action :set_contact, only: %i[ edit update destroy ]
  before_action :set_contact_type_options, only: %i[ create edit new update ]
  before_action :set_new_contact_from_params, only: :create 
  before_action :set_contact_type, only: %i[ update create ]

  def index
    @contacts = Contact.includes([:contact_type]).all
  end

  def new
    @contact = Contact.new
  end

  def edit
  end

  def create
    respond_to do |format|
      if @contact.save
        format.html { redirect_to contacts_url, notice: "Contact was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
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
    @contact.destroy
    respond_to do |format|
      format.html { redirect_to contacts_url, notice: "Address was successfully destroyed." }
    end
  end

  def contacts_search
    search_term = contacts_search_param[:contacts_search_value]&.downcase

    filters = params[:search_filters]&.split(',')

    @contacts = ContactsSearchService.new(filters: filters, search_term: search_term).call

    render :contacts_search, layout: nil
  end

  private

    def set_contact
      @contact = Contact.includes(:contact_type).find(params[:id])
    end

    def set_new_contact_from_params
      @contact = Contact.new(contact_params)
    end

    def set_contact_type_options
      @contact_types = CategoryReference.list_by_category(:contact_type)
    end

    def set_contact_type
      if contact_type_params[:contact_type_id]
        @contact_type = CategoryReference.find(contact_type_params[:contact_type_id])
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
        :email
      )
    end

    def contact_type_params
      params.require(:contact).permit(
        :contact_type_id
      )
    end

    def contacts_search_param
      params.permit(:contacts_search_value)
    end
end
