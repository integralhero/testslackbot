require 'slack-ruby-client'
require "httparty"
CHIMEBOT_ID = "U25FSAV6Y"
DEBUG_MODE = false

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

def get_user_session(id)
	puts "Received #{id}"
	date = Time.now.strftime("%m%d%Y")
	return "#{id.to_s}#{date}"
end

client = Slack::RealTime::Client.new
client.on :message do |data|
	if data['user'] != CHIMEBOT_ID
		session_id = get_user_session(data['user'])
		timenow = Time.now.strftime("%Y%m%d")
		api_key_wit = ENV['WIT_API_TOKEN']
		response = HTTParty.post('https://api.wit.ai/converse?', :query => {:v => '#{timenow}',:session_id => session_id, :q =>"#{data.text}"}, :headers => {"Authorization" => "Bearer #{api_key_wit}"})
		client.message channel: data['channel'], text: "#{response.to_s}" if DEBUG_MODE
		puts response["type"]
		case response["type"]
		when "msg"
			client.message channel: data['channel'], text: "#{response["msg"]}"
		else
			puts "None matched"
			client.message channel: data['channel'], text: "Hi <@#{data['user']}>! You said: #{data.text}"
		end
		
	end
end
client.start!
