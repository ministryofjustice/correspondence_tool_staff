class CorrespondenceController < ApplicationController

  before_action :set_correspondence, only: [:show, :edit, :update, :assign]

  def index
    @correspondence = Correspondence.all
  end

  def new
    @correspondence = Correspondence.new
    render :new
  end

  def create
    @correspondence = Correspondence.new(create_foi_params)

    if @correspondence.save
      flash[:notice] = "Case successfully created"
      redirect_to correspondence_index_path
    else
      render :new
    end
  end

  def show; end

  def edit
    render :edit
  end

  def update
    if @correspondence.update(parsed_edit_params)
      flash.now[:notice] = "Correspondence updated"
      render :show
    else
      render :edit
    end
  end

  def assign
    if @correspondence.update(assign_params) && @correspondence.drafter
      flash.now[:notice] = "Case assigned to #{@correspondence.drafter.email}"
    end
    render :show
  end

  def search
    @correspondence = Correspondence.search(params[:search])
    render :index
  end

  private

  def create_foi_params
    params.require(:correspondence).permit(
      :name,
      :postal_address,
      :email, :email_confirmation,
      :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy
    ).merge(category_id: Category.find_by(abbreviation: 'FOI').id)
  end

  def parsed_edit_params
    edit_params.delete_if { |_key, value| value == "" }
  end

  def edit_params
    params.require(:correspondence).permit(
      :category_id
    )
  end

  def assign_params
    params.require(:correspondence).permit(
      :user_id
    )
  end

  def set_correspondence
    @correspondence = Correspondence.find(params[:id])
  end

end
