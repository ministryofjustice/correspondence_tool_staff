class Cases::LettersController < ApplicationController
  before_action :set_case

  def new
    @type = type_name(params[:type])
    @letter = Letter.new(params[:letter_template_id])
    @letter_templates = LetterTemplate.where(template_type: @type)
  end

  def render_letter
    @type = params[:type]
    unless params[:letter] and params[:letter][:letter_template_id]
      flash[:notice] = 'Please select a template.'
      redirect_to new_case_letters_path(@case.id, @type) and return
    end
    letter_template_id = params[:letter][:letter_template_id]
    @letter = Letter.new(letter_template_id)
    @letter_template = LetterTemplate.find(letter_template_id)
  end

  private

  def set_case
    @case = Case::Base.find(params[:case_id])&.decorate
  end

  def type_name(type)
    LetterTemplate.template_types[type] || 'unknown'
  end
end
