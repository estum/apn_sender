# -*- coding: utf-8 -*-
require 'spec_helper'
describe APN::Notification do

  let(:token) { "2589b1aa 363d23d8 d7f16695 1a9e3ff4 1fb0130a 637d6997 a2080d88 1b2a19b5" }
  let(:payload) {"fake"}
  let(:notification) do
    APN::Notification.new(token, payload)
  end

  describe ".payload" do

    let(:message) do
      notification.payload
    end

    context "when payload is a string" do
      let(:payload) { "hi" }

      it "adds 'aps' key" do
        expect(ActiveSupport::JSON::decode(message)).to have_key('aps')
      end

      it "encode the payload" do
        expect(message)
          .to eq(ActiveSupport::JSON::encode(aps: {alert: payload}))
      end
    end

    context "when payload is a hash" do
      let(:payload) do
        {alert: 'paylod'}
      end

      it "adds 'aps' key" do
        expect(ActiveSupport::JSON::decode(message)).to have_key('aps')
      end

      it "encode the payload" do
        expect(message)
          .to eq(ActiveSupport::JSON::encode(aps: payload))
      end
    end

    [1, true].each do |v|
      context "when content_available is #{v}" do
        let(:payload) do
          {content_available: v}
        end

        it "adds to the message" do
          expect(message)
            .to eq(ActiveSupport::JSON::encode(aps: {'content-available' => 1}))
        end
      end
    end

    context "when payload is Localizable" do
      pending
    end
  end

  describe ".token" do

    context "when is a valid token" do

      it "has 32 byte size" do
        expect([notification.token].pack("H*").bytesize).to eq(32)
      end
    end

    context "when token doesnt have spaces" do
      let(:token) { "2589b1aa363d23d8d7f166951a9e3ff41fb0130a637d6997a2080d881b2a19b5" }

      it "has 32 byte size" do
        expect([notification.token].pack("H*").bytesize).to eq(32)
      end
    end

    context "when token is more that 32 bytes" do
      let(:token) { "9b1e2" * 50 }

      it "raises" do
        pending
      end
    end
  end
end
