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
	puts data.inspect
	response = HTTParty.post('https://api.wit.ai/converse?', :query => {:session_id => "#{session_id}", :q =>"How do I add money from a debit card?"}, :header => {"Authorization" => "Bearer #{ENV['WIT_API_WOKEN']}"})
	client.message channel: data['channel'], text: "Hi <@#{data['user']}>!"
end
client.start!
