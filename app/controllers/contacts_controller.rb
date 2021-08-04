class ContactsController < ApplicationController
  before_action :set_contact, only: %i[ edit update destroy ]

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

  def contacts_search
    @contacts = Contact.where(name: contacts_search_param[:contacts_search_value])

    json = @contacts.map do |contact| 
      { name: contact.name, address: contact.address } 
    end

    render json: json
  end

  private
    def set_contact
      @contact = Contact.find(params[:id])
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

    def contacts_search_param
      params.permit(:contacts_search_value)
    end
end
