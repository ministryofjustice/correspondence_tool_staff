class Cases::LettersController < ApplicationController
  before_action :set_case

  def new
    @letter_templates = LetterTemplate.all
  end

  def render_letter
    @letter_template = LetterTemplate.find(params[:letter_template_id])
  end

  private

  def set_case
    @case = Case::Base.find(params[:case_id])
  end
end
