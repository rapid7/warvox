class ApplicationController < ActionController::Base
	helper :all
	protect_from_forgery
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
		return true
		
		if(not check_auth())
			response.headers["Status"] = "Unauthorized" 
			response.headers["WWW-Authenticate"] = 'Basic realm="WarVOX Console"'
			render :text => "Authentication Failure", :status => 401  			
			return
		end
		true
	end
		
end
