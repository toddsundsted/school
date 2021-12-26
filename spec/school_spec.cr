require "./spec_helper"

Spectator.describe School do
  describe "::VERSION" do
    it "should return the version" do
      version = YAML.parse(File.read(File.join(__DIR__, "..", "shard.yml")))["version"].as_s
      expect(School::VERSION).to eq(version)
    end
  end
end
