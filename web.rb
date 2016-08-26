require 'sinatra/base'
module SlackChimebot
	class Web < Sinatra::Base
		get '/' do
			"Math is good for u"
		end
	end
end