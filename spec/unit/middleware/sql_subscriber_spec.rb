require "spec_helper"

RSpec.describe InfluxDB::Rails::Middleware::SqlSubscriber do
  let(:config) { InfluxDB::Rails::Configuration.new }
  let(:logger) { double(:logger) }

  before do
    allow(config).to receive(:application_name).and_return("my-rails-app")
    allow(config).to receive(:ignored_environments).and_return([])
    allow(config).to receive(:time_precision).and_return("ms")
  end

  describe ".call" do
    let(:start_time)   { Time.at(1_517_567_368) }
    let(:finish_time)  { Time.at(1_517_567_370) }
    let(:series_name) { "series_name" }
    let(:payload) { { sql: "SELECT * FROM POSTS WHERE id = 1", name: "Post Load", binds: %w[1 2 3] } }
    let(:result) do
      {
        values:    {
          value: 2000,
          sql:   "SELECT * FROM POSTS WHERE id = xxx"
        },
        tags:      {
          location:   "Foo#bar",
          operation:  "SELECT",
          class_name: "Post",
          name:       "Post Load",
        },
        timestamp: 1_517_567_370_000
      }
    end

    subject { described_class.new(config, series_name) }

    before do
      InfluxDB::Rails.current.controller = "Foo"
      InfluxDB::Rails.current.action = "bar"
    end

    after do
      InfluxDB::Rails.current.reset
    end

    context "successfully" do
      it "writes to InfluxDB" do
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(
          series_name, result
        )
        subject.call("name", start_time, finish_time, "id", payload)
      end

      context "with not relevant queries" do
        before do
          payload[:sql] = "SHOW FULL FIELDS FROM `users`"
        end

        it "does not write to InfluxDB" do
          expect_any_instance_of(InfluxDB::Client).not_to receive(:write_point)
          subject.call("name", start_time, finish_time, "id", payload)
        end
      end
    end

    context "unsuccessfully" do
      before do
        allow(config).to receive(:logger).and_return(logger)
        InfluxDB::Rails.configuration = config
      end

      it "does log exceptions" do
        allow_any_instance_of(InfluxDB::Client).to receive(:write_point).and_raise("boom")
        expect(logger).to receive(:error).with(/boom/)
        subject.call("name", start_time, finish_time, "id", payload)
      end
    end
  end
end
