require "serialport"
require "twitter"

# params for serial port
port_str = "/dev/tty.usbserial-A900cdNp"
baud_rate = 9600
data_bits = 8
stop_bits = 1
parity = SerialPort::NONE

sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

# twitter auth
require './Config.rb'
Twitter.configure do |config|
  config.consumer_key = YOUR_CONSUMER_KEY
  config.consumer_secret = YOUR_CONSUMER_SECRET
  config.oauth_token = YOUR_OAUTH_TOKEN
  config.oauth_token_secret = YOUR_OAUTH_TOKEN_SECRET  
end

client = Twitter::Client.new

line = "";
while true do
  getc = sp.getc
  if getc
    line += getc

    if getc == "\n"
      # post
      puts line
      client.update(line)
      
      line = ""
    end
  end
end

sp.close