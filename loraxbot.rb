require 'slack-ruby-client'
require "httparty"
CHIMEBOT_ID = "U25FSAV6Y"


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
	puts data.text
	timenow = Time.now.strftime("%Y%m%d")
	response = HTTParty.post('https://api.wit.ai/converse?', :query => {:v => '#{timenow}',:session_id => "#{session_id}", :q =>"#{data.text}"}, :headers => {"Authorization" => "Bearer EQ5MQVUHXZ473HSKP3TRCLKDUSRC3C3D"})
	client.message channel: data['channel'], text: "#{response.to_s}"
	client.message channel: data['channel'], text: "Hi <@#{data['user']}>! You said: #{data.text}"
end
client.start!
