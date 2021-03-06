module CacheHelper

	def dalli_client
		options = { :namespace => "app_v1", :compress => true }
		dc = Dalli::Client.new(ENV['MEMCACHED_HOST'], options)
	end

	""" semester caching methods """

	""" member caching methods """
	def clear_member_cache
		Rails.cache.write('member_email_hash', nil)
		Rails.cache.write('current_members', nil)
	end
	
	def current_members
		a = Rails.cache.read('current_members')
		if a != nil
			return a
		end
		a = ParseMember.current_members
		Rails.cache.write('current_members', a)
		return a
	end

	def member_email_hash
		a = Rails.cache.read('member_email_hash')
		if a != nil
			return a
		end
		a = ParseMember.limit(10000).all.index_by(&:email)
		Rails.cache.write('member_email_hash', a)
		return a
	end

	def committee_member_hash
		h = Hash.new
		member_email_hash.values.each do |member|
			if member.committee and not h.keys.include?(member.committee)
				h[member.committee] = Array.new
			end
			h[member.committee] << member.email
		end
		return h
	end

	""" tabling caching methods """

	""" points caching methods """


	""" permissions caches """ 
	def email_lookup_hash
	end

	""" go key caching methods """
	def clear_go_cache
		# Rails.cache.write("go_link_hash", nil)
		Rails.cache.write("go_link_key_hash", nil)
		Rails.cache.write("go_link_favorite_hash", nil)
		Rails.cache.write("go_link_tag_hash", nil)
		Rails.cache.write("go_link_ratings", nil)
		Rails.cache.write('tag_color_hash', nil)
	end

	def go_link_ratings
		a = Rails.cache.read('go_link_ratings')
		if a != nil
			return a
		end
		a = ParseGoLinkRating.limit(100000).all.to_a 
		Rails.cache.write('go_link_ratings', a)
		return a
	end

	def go_link_tag_hash
		a = Rails.cache.read('go_link_tag_hash')
		if a != nil
			return a
		end
		a = ParseGoLink.tag_hash 
		Rails.cache.write('go_link_tag_hash', a)
		return a
	end

	def go_link_favorite_hash
		a = Rails.cache.read('go_link_favorite_hash')
		if a != nil
			return a
		end
		a = GoLinkFavorite.hash 
		Rails.cache.write('go_link_favorite_hash', a)
		return a
	end

	def invalidate_go_link_favorite_hash
		Rails.cache.write("go_link_favorite_hash", nil)
	end

	def invalidate_cached_collections
		Rails.cache.write('cached_golink_collections', nil)
	end
	def cached_golink_collections
		a = Rails.cache.read('cached_golink_collections')
		if a != nil
			return a
		end
		a = ParseGoLinkCollection.limit(100000).all.to_a 
		Rails.cache.write('cached_golink_collections', a)
		return a
	end

	def golink_permissions
		dc = dalli_client
		return dc.get('golink_permissions_hash')
	end
	def cached_golinks
		dc = dalli_client
		return dc.get('golinks')
	end
	def go_link_key_hash
		dc = dalli_client
		return dc.get('go_key_hash')
	end
	def golink_key_hash
		dc = dalli_client
		return dc.get('golink_key_hash')
	end

	def go_tag_links
		dc = dalli_client
		return dc.get('tag_links')
	end

	def go_tag_hash
		a = dalli_client.get('go_tag_hash')
		return a ? a : Hash.new
	end

	def go_tags
		a =  dalli_client.get('go_tags')
		return a ? a : Array.new
	end



	# def go_link_hash
	# 	a = Rails.cache.read('go_link_hash')
	# 	if a != nil
	# 		return a
	# 	end
	# 	a = ParseGoLink.limit(10000).all.index_by(&:id)
	# 	Rails.cache.write('go_link_hash', a)
	# 	return a
	# end

	""" tasks cache """

	def clear_tasks_cache
		Rails.cache.write('registered_boards', nil)
		Rails.cache.write('main_board', nil)
		Rails.cache.write('label_hash', nil)
		Rails.cache.write('trello_list_hash', nil)
		Rails.cache.write('trello_board_members_hash', nil)
		Rails.cache.write('trello_card_hash', nil)
	end

	def clear_card_cache
		Rails.cache.write('trello_card_hash', nil)
	end

	""" trello id to ParseMember """
	def trello_member_hash
		puts 'called trello_member_hash'
		h = Hash.new
		current_members.select{|x| x.has_trello}.each do |member|
			h[member.trello_member_id] = member
		end
		return h
		# index_by(&:trello_member_id)
	end

	def registered_boards
		a = Rails.cache.read('registered_boards')
		if a != nil
			return a
		end
		a = ParseTrelloBoard.registered_boards
		Rails.cache.write('registered_boards', a)
		return a
	end

	def main_board
		a = Rails.cache.read('main_board')
		if a != nil
			return a
		end
		a = ParseTrelloBoard.main_board
		Rails.cache.write('main_board', a)
		return a
	end

	def trello_label_hash
		a = Rails.cache.read('label_hash')
		if a != nil
			return a
		end
		a = ParseTrelloBoard.label_hash
		Rails.cache.write('label_hash', a)
		return a
	end

	def trello_list_hash
		a = Rails.cache.read('trello_list_hash')
		if a != nil
			return a
		end
		a = ParseTrelloList.list_hash
		Rails.cache.write('trello_list_hash', a)
		return a
	end

	def trello_board_members_hash
		a = Rails.cache.read('trello_board_members_hash')
		if a != nil
			return a
		end
		members = current_members
		a = Hash.new
		registered_boards.values.each do |board|
			board_id = board.board_id
			ids = board.member_ids
			m = members.select{|x| ids.include?(x.trello_member_id) and x.email != nil}.map{|x| x.email}
			a[board_id] = m
		end
		Rails.cache.write('trello_board_members_hash', a)
		return a
	end

	def trello_card_hash
		a = Rails.cache.read('trello_card_hash')
		if a != nil
			return a
		end
		a = ParseTrelloCard.limit(10000).all.index_by(&:card_id)
		Rails.cache.write('trello_card_hash', a)
		return a
	end


end
