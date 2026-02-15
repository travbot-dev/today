module Api
  module V1
    class DailyDigestController < BaseController
      require_scope :read

      def show
        date = params[:date] ? Date.parse(params[:date]) : Time.current.to_date
        service = DailyDigestService.new(current_user, date: date)

        render json: service.call.merge(generated_at: Time.current.iso8601)
      rescue ArgumentError => e
        render json: { error: "Invalid date format" }, status: :bad_request
      end
    end
  end
end
