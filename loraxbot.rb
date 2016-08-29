require 'slack-ruby-bot'
require 'logger'


logger = Logger.new(STDOUT)

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

client = Slack::RealTime::Client.new
client.on :message do |data|
	client.message channel: data['channel'], text: "Hi <@#{data['user']}>!"
end
client.start!

# class LoraxBot < SlackRubyBot::Bot

#   def self.generate_session_id(data)
#   	user_id = data['user']['id']
#   	return user_id + Time.now.strftime("%m/%d/%Y")
#   end
  
#   match '/(?<message>.*)/s' do |client, data, match|
#     client.say(channel: data.channel, text: "Hello there, you said #{match[:message]}!")
#     logger.info " Generated session_id: #{LoraxBot.generate_session_id(data)}"
#   end

#   match /^How is the weather in (?<location>\w*)\?$/ do |client, data, match|
#     client.say(channel: data.channel, text: "The weather in #{match[:location]} is nice.")
#     logger.info " Generated session_id: #{LoraxBot.generate_session_id(data)}"
#   end
# end

# LoraxBot.run