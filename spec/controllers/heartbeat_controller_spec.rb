require "rails_helper"

RSpec.describe HeartbeatController, type: :controller do
  describe "#ping" do
    it "returns JSON with app information" do
      get :ping

      ping_response = JSON.parse response.body
      # Settings can be nil, and since we don't test Settings anywhere else we do it here.
      expect(ping_response["build_date"]).not_to be_nil
      expect(ping_response["build_date"]).to eq Settings.build_date
      expect(ping_response["git_commit"]).not_to be_nil
      expect(ping_response["git_commit"]).to eq Settings.git_commit
      expect(ping_response["build_tag"]).not_to be_nil
      expect(ping_response["build_tag"]).to eq Settings.git_source
    end
  end

  describe "#healthcheck" do
    before do
      retry_set = instance_double(Sidekiq::RetrySet, size: 0)
      allow(Sidekiq::RetrySet).to receive(:new).and_return(retry_set)
    end

    context "when a problem exists" do
      before do
        process_set = instance_double(Sidekiq::ProcessSet, size: 0)
        allow(Sidekiq::ProcessSet).to receive(:new).and_return(process_set)
        dead_set = instance_double(Sidekiq::DeadSet, size: 1)
        allow(Sidekiq::DeadSet).to receive(:new).and_return(dead_set)
        redis = double("Redis") # rubocop:disable RSpec/VerifiedDoubles
        allow(Sidekiq).to receive(:redis).and_yield(redis)
        allow(redis).to receive(:info).and_raise(Errno::ECONNREFUSED)
        allow(ActiveRecord::Base.connection)
          .to receive(:execute).and_raise(PG::ConnectionBad)

        get :healthcheck
      end

      it "returns status bad gateway" do
        expect(response.status).to eq(502)
      end

      it "returns the expected response report" do
        expect(response.body).to eq({ checks: {
          database: false,
          redis: false,
          sidekiq: false,
          sidekiq_queue: false,
        } }.to_json)
      end
    end

    context "when everything is ok" do
      before do
        process_set = instance_double(Sidekiq::ProcessSet, size: 1)
        allow(Sidekiq::ProcessSet).to receive(:new).and_return(process_set)
        dead_set = instance_double(Sidekiq::DeadSet, size: 0)
        allow(Sidekiq::DeadSet).to receive(:new).and_return(dead_set)
        allow(Sidekiq).to receive(:redis_info).and_return({})

        get :healthcheck
      end

      it "returns HTTP success" do
        expect(response.status).to eq(200)
      end

      it "returns the expected response report" do
        expect(response.body).to eq({ checks: {
          database: true,
          redis: true,
          sidekiq: true,
          sidekiq_queue: true,
        } }.to_json)
      end
    end
  end
end
