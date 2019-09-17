class LetterForm
  include ActiveModel::Conversion
  extend  ActiveModel::Naming
  attr_accessor :letter_template_id

  def initialize(letter_template_id)
    @letter_template_id = letter_template_id
  end
end

class Cases::LettersController < ApplicationController
  before_action :set_case

  def new
    @type = params[:type]
    @letter = LetterForm.new(params[:letter_template_id])
    @letter_templates = LetterTemplate.where(template_type: @type)
  end

  def render_letter
    @type = params[:type]
    unless params[:letter_form] and params[:letter_form][:letter_template_id]
      flash[:notice] = 'Please select a template.'
      redirect_to new_case_letters_path(@case.id, @type) and return
    end
    letter_template_id = params[:letter_form][:letter_template_id]
    @letter = LetterForm.new(letter_template_id)
    @letter_template = LetterTemplate.find(letter_template_id)
  end

  private

  def set_case
    @case = Case::Base.find(params[:case_id])&.decorate
  end
end
