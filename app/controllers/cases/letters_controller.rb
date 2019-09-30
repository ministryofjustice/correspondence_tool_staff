class Cases::LettersController < ApplicationController
  before_action :set_case, :set_type
  before_action :check_template_selected, only: [:show]

  def new
    @letter = Letter.new(params[:letter_template_id])
    @letter_templates = LetterTemplate.where(template_type: @type)
  end

  def show
    letter_template_id = letter_params[:letter_template_id]
    @letter = Letter.new(letter_template_id)
    @letter_template = LetterTemplate.find(letter_template_id)
  end

  private

  def check_template_selected
    unless params.dig(:letter, :letter_template_id)
      flash[:notice] = 'Please select a template.'
      redirect_to new_case_letters_path(@case.id, @type) and return
    end
  end

  def set_type
    @type = LetterTemplate.type_name(params[:type])
  end

  def set_case
    @case = Case::Base.find(params[:case_id])&.decorate
  end

  def letter_params
    params.require(:letter).permit(:letter_template_id)
  end
end
