class Event < ActiveRecord::Base
  attr_accessible :name, :start_time, :end_time, :description, :semester_id, :google_id, :points, :date, :location
  belongs_to :semester, foreign_key: :semester_id
  has_many :event_members #, dependent: :destroy
  validates :semester_id, uniqueness: true

  def self.this_semester
    return Event.where(semester_id: Semester.current_semester.id)
  end



  def time_string
    t = self.start_time
    day = t.strftime("%d")
    month = t.strftime("%b")
    year = t.strftime("%Y")
    return month + " " + day + ", " + year
  end


  def attendees
    event_mem_ids = EventMember.where(event_id: self.id.to_s).pluck(:member_id)
    return Member.where('id IN (?)', event_mem_ids)
  end

  def attendance_rate(committee)
    attendees = self.attendees
    cms = Member.currently_in_committee(committee).pluck(:id)
    total_cms = cms.length
    count = attendees.where('id IN (?)', cms).length
    return [count, total_cms, (count.to_f/total_cms)]
  end

  def self.google_events_list

  end

  """ convenience methods """


  def self.construct_from_google(google_event)
    """ constructs event from pulled google event """
  end


end
