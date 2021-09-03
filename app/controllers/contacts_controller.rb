class ContactsController < ApplicationController
  before_action :set_contact, only: %i[ edit update destroy ]
  before_action :set_address_types, only: %i[ edit new ]

  def index
    @contacts = Contact.all
  end

  def new
    @contact = Contact.new
  end

  def edit
  end

  def create
    @contact = Contact.new(contact_params)

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

  private
    def set_contact
      @contact = Contact.find(params[:id])
    end

    def set_address_types
      @address_types = CategoryReference.list_by_category(:address_type)
    end

    def contact_params
      params.require(:contact).permit(
        :name, 
        :address_line_1,
        :address_line_2, 
        :town,
        :county,
        :postcode,
        :email,
        :contact_type
      )
    end
end
