class CasesController < ApplicationController

  before_action :set_case, only: [:show, :edit, :update]

  def index
    @cases = Case.by_deadline
  end

  def new
    @case = Case.new
    render :new
  end

  def create
    @case = Case.new(create_foi_params)

    if @case.save
      flash[:notice] = t('.case_created')
      redirect_to new_case_assignment_path @case
    else
      render :new
    end
  end

  def show; end

  def edit
    render :edit
  end

  def update
    if @case.update(parsed_edit_params)
      flash.now[:notice] = t('.case_updated')
      render :show
    else
      render :edit
    end
  end

  def search
    @case = Case.search(params[:search])
    render :index
  end

  private

  def create_foi_params
    params.require(:case).permit(
      :name,
      :postal_address,
      :email, :email_confirmation,
      :subject, :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy
    ).merge(category_id: Category.find_by(abbreviation: 'FOI').id)
  end

  def parsed_edit_params
    edit_params.delete_if { |_key, value| value == "" }
  end

  def edit_params
    params.require(:case).permit(
      :category_id
    )
  end

  def assign_params
    params.require(:case).permit(
      :user_id
    )
  end

  def set_case
    @case = Case.find(params[:id])
  end

end
