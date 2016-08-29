require 'slack-ruby-client'
require 'wit'

CHIMEBOT_ID = "U25FSAV6Y"

actions = {
	send: -> (request, response) {
    	puts("sending... #{response['text']}")
  	}
}

wit_client = Wit.new(access_token: ENV['WIT_API_TOKEN'], actions: actions)

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

def get_user_session(id)
	puts "Received #{id}"
	date = Time.now.strftime("%m/%d/%Y")
	return "#{id.to_s} #{date}"
end

client = Slack::RealTime::Client.new
client.on :message do |data|
	return if data['user'] == CHIMEBOT_ID
	session_id = get_user_session(data['user'])
	rsp = client.converse(session_id, 'what is the weather in London?', {})
	puts("Yay, got Wit.ai response: #{rsp}")
	client.message channel: data['channel'], text: "Hi <@#{data['user']}>!"
end
client.start!
