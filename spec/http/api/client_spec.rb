require "spec_helper"

RSpec.describe Http::Api::Client do
  it "has a version number" do
    expect(Http::Api::Client::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
