module Api
  module V1

    class CorrespondenceController < Api::ApplicationController

      def create
        @correspondence = Correspondence.new(correspondence_params)

        if @correspondence.save
          render json: @correspondence.id, status: :created
        else
          render json: { errors: @correspondence.errors }, status: 422
        end
      end

      private

      def correspondence_params
        params.require(:correspondence).permit(
          :name,
          :email, :email_confirmation,
          :category_id,
          :message,
          :received_date_dd, :received_date_mm, :received_date_yyyy
        )
      end
    end
  end
end
