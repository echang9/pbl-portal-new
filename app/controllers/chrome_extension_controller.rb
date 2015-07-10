class ChromeExtensionController < ApplicationController
	def create_go_link
		key = params[:key]
		url = params[:url]
		description = params[:description]
		directory = params[:directory] != "" ? params[:directory] : '/PBL'
		""" do some error checking """
		errors = Array.new
		if not ParseGoLink.valid_key(key)
			errors << "key"
		end
		if not ParseGoLink.valid_url(url)
			errors << "url"
		end
		if not ParseGoLink.valid_directory(directory)
			errors << "directory"
		end
		""" if there are errors, return with errors """
		if errors.length > 0
			render json: "Error with creating link", :status=>500, :content_type=>'text/html'
		else
			""" save the new link """
			golink = ParseGoLink.new(key: key, url: url, description: description, directory: directory)
			if current_member
				golink.member_email = current_member.email
			end
			golink.save
			clear_go_cache
			# render :nothing => true, :status => 200, :content_type => 'text/html'
			response.headers['Access-Control-Allow-Origin'] = '*'
			response.headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
			response.headers['Access-Control-Request-Method'] = '*'
			response.headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
			render json: "<h3>Successfully created link</h3><p><h3>View your link at pbl.link/"+golink.key+"</h3></p>", :status=>200, :content_type=>'text/html'
		end
	end

	def lookup_url
		matches = go_link_hash.values.select{|x| x.url == params[:url]}
		match_string = ""
		matches.each do |match|
			match_string += "<div><b>" + match.key + "</b></div>"
		end
		response.headers['Access-Control-Allow-Origin'] = '*'
		response.headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
		response.headers['Access-Control-Request-Method'] = '*'
		response.headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
		render json: "<h3>Matches</h3>"+match_string, :status=>200, :content_type=>'text/html'
	end
end