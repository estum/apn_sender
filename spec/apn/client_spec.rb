require 'spec_helper'
describe APN::Client do

  let(:socket) { double("SSLSocket") }
  let(:token)        { "2589b1aa 363d23d8 d7f16695 1a9e3ff4 1fb0130a 637d6997 a2080d88 1b2a19b5" }
  let(:notification) { APN::Notification.new(token.gsub(/\W/, ''), alert: "hi")}

  describe ".push" do

    let(:client) do
      APN::Client.new
    end

    before do
      expect(client).to receive(:socket).at_least(1).and_return(socket)
      IO.should_receive(:select).and_return(false)
    end

    context "when pushing a message" do

      it "sends write to socket" do
        # socket.stub(:flush)
        socket.should_receive(:write).with(notification.message)
        client.push(notification)
      end
    end
  end

  describe ".socket" do

    let(:certificate) { double("certificate") }

    before do
      APN::Client.any_instance.should_receive(:setup_certificate).and_return(certificate)
    end

    context "when not passing args" do

      let(:client) do
        APN::Client.new
      end

      it "tries to connect using default host and port" do
        TCPSocket.should_receive(:new).with(APN::Client::DEFAULTS[:host], APN::Client::DEFAULTS[:port])
        OpenSSL::SSL::SSLSocket.should_receive(:new).and_return(socket)
        socket.stub(:sync=)
        socket.stub(:connect)

        client.socket
      end
    end

    context "when passing host and port nil" do

      let(:client) do
        APN::Client.new(host: nil, port: nil)
      end

      it "tries to connect using default host and port" do
        TCPSocket.should_receive(:new).with(APN::Client::DEFAULTS[:host], APN::Client::DEFAULTS[:port])
        OpenSSL::SSL::SSLSocket.should_receive(:new).and_return(socket)
        socket.stub(:sync=)
        socket.stub(:connect)

        client.socket
      end

    end
  end
end
