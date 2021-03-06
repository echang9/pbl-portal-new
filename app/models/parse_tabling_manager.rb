class ParseTablingManager < ParseResource::Base

	fields :name, :type, :data, :time

	def self.get_tabling_schedule
		 """ returns the tabling schedule in a Hash
		key is tabling day (0 to 6)
		value is Array of TablingSlot objects sorted by time
		"""
		# schedule = Rails.cache.read('tabling_schedule')
		# if schedule != nil
		# 	return schedule
		# end

		schedule = Hash.new
		tabling_slots = ParseTablingSlot.all.to_a
		tabling_slots.each do |tabling_slot|

			# put this slot into the day key in the schedule
			if not schedule.keys.include?(tabling_slot.day) 
				schedule[tabling_slot.day] = Array.new
			end
			schedule[tabling_slot.day] << tabling_slot
		end
		# sort the schedule by tabling_slot time
		schedule.keys.each do |tabling_day|
			schedule[tabling_day].sort { |a, b| a.time <=> b.time}
		end

		Rails.cache.write('tabling_schedule', schedule)
		return schedule
	end

	def self.generate_tabling_schedule(times, members)
		""" takes a list of members and times and creates a tabling schedule""" 

		"""mock generate tabling schedule (comment off) """
		members = ParseMember.current_members
		times = 5.times.map{ Random.rand(167) } 

		assignments = self.generate_tabling_assignments(times, members)
		self.generate_tabling_slots(assignments)
	end

	def self.generate_tabling_slots(assignments)
		""" deletes all current tabling slots and regenerates tabling schedule
		"""
		Rails.cache.write('tabling_schedule', nil)
		ParseTablingSlot.destroy_all
		slots = Array.new
		assignments.keys.each do |time|
			ts = ParseTablingSlot.new
			ts.time = time
			# ts.member_ids = assignments[time].map {|x| x.email}
			ts.member_emails = assignments[time].map{|x| x.email}
			puts 'saving a tabling slot at time : ' + ts.time.to_s
			puts "\t" + ts.member_emails.to_s
			slots << ts
			ts.save
		end
		# ParseTablingSlot.save_all(slots)
	end

  def self.generate_tabling_assignments(times, members)
    """
    create assignment hash of timeslot (hour) to member list
    times is an Array of times that you want tabling to happen (like [5,7,4,34])
    members is a Array of member ids
    """
    unassigned = Set.new(members)
    assignments = Hash.new
    while unassigned.length() > 0
      mcv = get_MCV(unassigned, times)
      lcv = get_LCV(assignments, mcv, times)
      if not assignments.has_key?(lcv)
        assignments[lcv] = Array.new
      end
      assignments[lcv] << mcv
      unassigned.delete(mcv)
    end

    return assignments
  end

  def self.get_MCV(unassigned, times)
  	""" the MCV is the most constrained value, or the member with the least
  	available slots for this week
  	"""
    mcv = []
    max_clashes = -1
    unassigned.each do |member|
      commitments = member.commitments
      clashes = 0
      for time in times
        if commitments[time] == 1
          clashes += 1
        end
      end
      if clashes > max_clashes
        max_clashes = clashes
        mcv = [member]
      elsif clashes == max_clashes
        mcv << member
      end
    end

    mcv = mcv.sample
    return mcv
  end


  def self.get_LCV(assignments, member, times)
  	""" the LCV is the least constrained value, or the slot that 
  	has the least members so far
  	"""
    lcv = []
    min_capacity = 1000000
    times.each do |time|
      capacity = 0
      if assignments.has_key?(time)
        capacity = assignments[time].length
      end
      if capacity < min_capacity
        min_capacity = capacity
        lcv = [time]
      elsif capacity == min_capacity
        lcv << time
      end
    end

    lcv = lcv.sample
    return lcv
  end
end