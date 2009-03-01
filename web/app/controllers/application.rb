# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
	helper :all # include all helpers, all the time

	# See ActionController::RequestForgeryProtection for details
	# Uncomment the :secret if you're not using the cookie session store
	protect_from_forgery # :secret => 'e33bad7b4703e163bb4f5925513d26ec'

	# See ActionController::Base for details 
	# Uncomment this to filter the contents of submitted sensitive data parameters
	# from your application log (in this case, all fields with names like "password"). 
	filter_parameter_logging [:password, :pass]

	before_filter :get_auth

private

	def get_creds
		username = nil
		password = nil
		
		headers = %W{X-HTTP_AUTHORIZATION REDIRECT_X_HTTP_AUTHORIZATION HTTP_AUTHORIZATION}
	
		headers.each do |head|
			blob = request.env[head]
			next if not blob

			meth,blob = blob.split(/\s+/)	
			next if not blob
			next if meth.downcase != 'basic'
		
			username,password = blob.unpack('m*')[0].split(':', 2)
			break if (username and username.length > 0)
		end

		[username, password]
	end 

	def check_auth
		return true if session.data[:user]
		user,pass = get_creds
		return false if not (user and pass)
		
		if(WarVOX::Config.authenticate(user,pass))
			session.data[:user] = user
			return true
		end
		
		return false
	end
	
	def get_auth
		if(not check_auth())
			response.headers["Status"] = "Unauthorized" 
			response.headers["WWW-Authenticate"] = 'Basic realm="WarVOX Console"'
			render :text => "Authentication Failure", :status => 401  			
			return
		end
		true
	end
end
