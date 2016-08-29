require 'slack-ruby-bot'

class LoraxBot < SlackRubyBot::Bot

  def generate_session_id(data)
  	user_id = data['user']['id']
  	return user_id + Time.now.strftime("%m/%d/%Y")
  end
  
  command '' do |client, data, match|
    client.say(text: 'Hello there!', channel: data.channel)
    logger.info generate_session_id(data)
  end
end

LoraxBot.run