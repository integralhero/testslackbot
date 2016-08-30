require 'slack-ruby-client'
require "httparty"
CHIMEBOT_ID = "U25FSAV6Y"
DEBUG_MODE = true

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

def get_user_session(id)
	date = Time.now.strftime("%m%d%Y%H%M%S")
	return "#{id.to_s}#{date}"
end

client = Slack::RealTime::Client.new

client.on :reaction_added do |data|
	puts "Reaction is added: #{data.inspect}"
	client.message channel: data['item']['channel'], text: "Got a reaction: #{data['reaction']}!" if DEBUG_MODE
end

# General Message handler
# TODO: Currently generating unique session_id per call (per second). Not sure why, but I get low confidence back when I use an existing session and get no matches from Wit.ai
client.on :message do |data|
	if data['user'] != CHIMEBOT_ID
		session_id = get_user_session(data['user'])
		timenow = Time.now.strftime("%Y%m%d")
		api_key_wit = ENV['WIT_API_TOKEN']
		response = HTTParty.post('https://api.wit.ai/converse?', :query => {:v => '#{timenow}',:session_id => session_id, :q =>"#{data.text}"}, :headers => {"Authorization" => "Bearer #{api_key_wit}"})
		client.message channel: data['channel'], text: "#{response.to_s}" if DEBUG_MODE
		puts "Response from WIT: #{response.inspect}"
		case response["type"]
		when "msg"
			puts "Got a message"
			client.typing channel: data['channel']
			client.message channel: data['channel'], text: "#{response["msg"]}"
		when "action"
			action = response["action"]
		when "merge"
		else
			puts "None matched"
			client.message channel: data['channel'], text: "Hi <@#{data['user']}>! Your command was not recognized. Try testing me with some more common queries"
		end
		if response.key?("quickreplies")
			puts response["quickreplies"]
		end
		
	end
end
client.start!
