require 'slack-ruby-bot'

class LoraxBot < SlackRubyBot::Bot
  command 'trees' do |client, data, match|
    client.say(text: 'I speak for the trees', channel: data.channel)
  end
end


LoraxBot.run