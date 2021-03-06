# require 'chronic'
require 'set'
class TablingController < ApplicationController

  def commitments
  	commitments = current_member.commitments
  	@marked = Array.new
  	(0..167).each do |time|
  		if commitments[time] != 0
  			@marked << time
  		end
  	end
  end


  def manage
    @all_slots = TablingSlot.all
  end


	def index
    # @slots = TablingSlot.all
    @slots = ParseTablingManager.get_tabling_schedule
  end
	
	#
	# options for secretary to generate new tabling schedule
	#
	def options
		cms = Member.current_cms
	    officers = Member.current_chairs
	end

	#
	# generates tabling TODO background process
	#
	def generate
	    members = ParseMember.current_members
	    # times = 20..50
	    times = 20.times.map{ Random.rand(167) } 
	    assignments = ParseTablingManager.generate_tabling_schedule(times, members)
	   	redirect_to :controller => 'tabling', :action => 'index'
	end

	#
	# clears all slots this week
	#
	def delete_slots
		begin
			clear_this_week_slots
			render :nothing => true, :status => 200, :content_type => 'text/html'
		rescue
			render :nothing => true, :status => 500, :content_type => 'text/html'
		end
	end
end




 
