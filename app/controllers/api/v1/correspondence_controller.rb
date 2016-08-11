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
          :email,
          :email_confirmation,
          :category_id,
          :topic,
          :message
        )
      end
    end
  end
end
