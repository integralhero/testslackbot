require 'slack-ruby-client'
require "httparty"



CHIMEBOT_ID = "U25FSAV6Y"
DEBUG_MODE = true

$nums = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
$sessions = {}
actions = {}


Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

$web_client = Slack::Web::Client.new
client = Slack::RealTime::Client.new

# get_user_session
# PARAM: user_id from slack to generate session id for Wit
def get_user_session(user_id)
	date = Time.now.strftime("%m%d%Y%H%M%S")
	return "#{user_id.to_s}#{date}"
end

# clear_session_context_for_user
# PARAM: user_id from slack
def clear_session_context_for_user(user_id)
	if !$sessions.key? user_id 
		$sessions[user_id] = {}
	end
	$sessions[user_id]["context"] = {}
end

def get_context_for_user(user_id)
	if !$sessions.key? user_id
		$sessions[user_id] = {}
		$sessions[user_id]["context"] = {}
	else
		if !$sessions[user_id].key? "context"
			$sessions[user_id]["context"] = {}
		end
	end
	return $sessions[user_id]["context"]
end
def set_context_for_user(user_id, entities)
	return $sessions[user_id]["context"] = entities
end

def wit_converse(session_id, q, context="")
	api_key_wit = ENV['WIT_API_TOKEN']
	timenow = Time.now.strftime("%Y%m%d")
	response = HTTParty.post('https://api.wit.ai/converse?', :query => {:v => '#{timenow}',:session_id => session_id, :q =>"#{q}", :context => context}, :headers => {"Authorization" => "Bearer #{api_key_wit}"})
	return response
end

def post_quickreplies(quickreplies, data)
	# puts response["quickreplies"]
	index = 1
	emojis = []
	message = "Please select one of the following options for further inquiries: \n"
	for reply in quickreplies do
		num_as_emoji = ":#{$nums[index]}:"
		option_str = "#{num_as_emoji} #{reply} \n"
		message += option_str
		emojis.push("#{$nums[index]}")
		index += 1
	end
	puts "===========DATA===============> #{data.inspect}"
	channel_send = data['channel']
	channel_send = data['item']['channel'] if !channel_send
	chatbot_response = $web_client.chat_postMessage channel: channel_send, text: "#{message}", as_user: true
	puts "Chatbot result_response: #{chatbot_response.ts}"
	for i in 0...quickreplies.size
		session_id = data.user
		reply_text = quickreplies[i] 
		puts "Adding emoji: #{emojis[i]} on #{chatbot_response.channel} at #{chatbot_response.ts}" if DEBUG_MODE
		$web_client.reactions_add(name: emojis[i], channel: chatbot_response.channel, timestamp: chatbot_response.ts)
		$sessions[session_id] = {} if !$sessions.key? session_id
		$sessions[session_id][chatbot_response.channel] = {} if !$sessions[session_id].key? chatbot_response.channel
		$sessions[session_id][chatbot_response.channel][chatbot_response.ts] = {} if !$sessions[session_id][chatbot_response.channel].key? chatbot_response.ts
		# puts "SESSION PRINT: #{$sessions.inspect}" if DEBUG_MODE
		$sessions[session_id][chatbot_response.channel][chatbot_response.ts][emojis[i]] = reply_text
		
	end
end


# Slack handler for when a reaction is clicked
client.on :reaction_added do |data|

	puts "Reaction is added: #{data.inspect}"
	if data['user'] != CHIMEBOT_ID
		session_id = get_user_session(data['user'])

		message_ts = data['item']['ts']
		message_channel = data['item']['channel']
		reaction_name = data['reaction']
		puts "$sessions: #{$sessions.inspect}" if DEBUG_MODE

		puts "#{data['user']} just added a #{reaction_name} to #{message_channel} at #{message_ts}" if DEBUG_MODE
		if !$sessions.key?(data['user']) || !$sessions[data['user']].key?(message_channel) || !$sessions[data['user']][message_channel].key?(message_ts) || !$sessions[data['user']][message_channel][message_ts].key?(reaction_name)
			#handler just to be safe (in case sessions wasn't saved correctly, or a reaction was added that wasn't on the list of options)
			puts "Error in reaction handler"
		end

		# user_selected has the text corresponding to the user's chosen option
		user_selected = "#{$sessions[data['user']][message_channel][message_ts][reaction_name]}"
		puts user_selected if DEBUG_MODE
		# client.message channel: data['item']['channel'], text: "User selected-> #{user_selected}!" if DEBUG_MODE
		puts "Retrieved user context: #{get_context_for_user(data.user)}"

		# message Wit with the user's response
		wit_response = wit_converse(data.user, user_selected, get_context_for_user(data.user))
		puts "Response from wit for reaction: #{wit_response.inspect}"
		set_context_for_user(data.user, wit_response["entities"]) if wit_response.key? "entities"
		result_response = wit_response

		# should probably loop this part and break on a stop?
		# reached_stop = false

		# while !reached_stop
		# end

		case wit_response["type"]
		when "msg"
			client.typing channel: message_channel
			puts "Sending to client: #{result_response['msg']}" if DEBUG_MODE
			client.message channel: message_channel, text: "#{result_response["msg"]}"
		when "stop"
			puts "go to stop" if DEBUG_MODE
			api_key_wit = ENV['WIT_API_TOKEN']
			# clear_session_context_for_user(data.user) <- should we clear context here?

			gotMessage = false
			while !gotMessage
				context = get_context_for_user(data["user"])
				new_response = HTTParty.post('https://api.wit.ai/converse?', :query => {:v => '#{timenow}',:session_id => session_id, :q =>"#{data.text}", :context => "#{context}"}, :headers => {"Authorization" => "Bearer #{api_key_wit}"})
				puts "new response: #{new_response.inspect}" if DEBUG_MODE
				if new_response["type"] == "msg"
					gotMessage = true 
					result_response = new_response
				end
			end
			
			client.typing channel: data['channel']
			puts "Sending to client: #{new_response['msg']}" if DEBUG_MODE
			client.message channel: data['channel'], text: "#{new_response["msg"]}"
		end
		
		if result_response.key?("quickreplies") 
			post_quickreplies(result_response["quickreplies"], data)
		end


		
	end
	
end

# General Message handler
# TODO: Currently generating unique session_id per call (per second). Not sure why, but I get low confidence back when I use an existing session and get no matches from Wit.ai
client.on :message do |data|
	if data['user'] != CHIMEBOT_ID
		session_id = get_user_session(data['user'])
		client.typing channel: data['channel']
		context = get_context_for_user(data.user)

		response = wit_converse(session_id, data.text, "#{context}")
		# client.message channel: data['channel'], text: "#{response.to_s}" if DEBUG_MODE
		puts "USER MESSAGE: #{data['text']}" if DEBUG_MODE
		puts "Response from WIT: #{response.inspect}" if DEBUG_MODE

		# update user's context if we have something in the response
		if response.key? "entities"
			puts "Updated context #{response["entities"]} and retrieval #{get_context_for_user(data.user)}"
			context = set_context_for_user(data.user, response["entities"])
		end
		case response["type"]
		when "msg"
			puts "Sending to client: #{response['msg']}" if DEBUG_MODE
			client.message channel: data['channel'], text: "#{response["msg"]}"
		when "action"
			action_name = response["action"]
			puts response.inspect if DEBUG_MODE
		when "stop"
			puts response["type"]
			api_key_wit = ENV['WIT_API_TOKEN']
			puts "go to stop" if DEBUG_MODE
			# clear_session_context_for_user(data.user)

			gotMessage = false
			while !gotMessage
				new_response = HTTParty.post('https://api.wit.ai/converse?', :query => {:v => '#{timenow}',:session_id => session_id, :q =>"#{data.text}", :context => "#{context}"}, :headers => {"Authorization" => "Bearer #{api_key_wit}"})
				puts "new response: #{new_response.inspect}" if DEBUG_MODE
				if new_response["type"] == "msg"
					gotMessage = true 
					response = new_response
				end
			end
			
			client.typing channel: data['channel']
			puts "Sending to client: #{new_response['msg']}" if DEBUG_MODE
			client.message channel: data['channel'], text: "#{new_response["msg"]}"
		else
			puts "None matched" if DEBUG_MODE
			client.message channel: data['channel'], text: "Hi <@#{data['user']}>! Your command was not recognized. Try testing me with some common queries"
		end

		# handles responses with quickreplies on Wit by displaying a selection list with emoji reactions
		post_quickreplies(response["quickreplies"], data)

	end
end
client.start!
