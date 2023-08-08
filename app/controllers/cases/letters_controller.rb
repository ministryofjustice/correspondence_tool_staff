class Cases::LettersController < ApplicationController
  before_action :set_case, :set_type
  before_action :check_template_selected, only: [:show]

  def new
    @letter = Letter.new(params[:letter_template_id])
    @letter_templates = LetterTemplate.where(template_type: @type).order(:abbreviation)
  end

  def show
    letter_template_id = letter_params[:letter_template_id]
    letter_template = LetterTemplate.find(letter_template_id)
    @letter = Letter.new(letter_template_id, @case)

    respond_to do |format|
      format.html
      format.docx do
        template_data = {
          values: @letter.values,
          recipient: @letter.name,
          'html:body': @letter.body,
          letter_date: @letter.letter_date,
          requester_reference: @letter.values.requester_reference,
          'html:letter_address': @letter.letter_address,
          telephone_number: @letter.telephone_number,
        }

        path = Rails.root.join("lib", "assets", letter_template.base_template_file_ref)
        template = Sablon.template(path)
        render plain: template.render_to_string(template_data)
      end
    end
  end

private

  def check_template_selected
    unless params.dig(:letter, :letter_template_id)
      flash[:alert] = "Please select a template."
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
