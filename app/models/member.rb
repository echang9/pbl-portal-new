# == Schema Information
#
# Table name: members
#
#  id             :integer          not null, primary key
#  provider       :string(255)
#  uid            :string(255)
#  name           :string(255)
#  remember_token :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  old_member_id  :integer
#

# == Description
#
# A member of the Portal
#
# == Fields
# - provider: the authorization provider
# - uid: ID of member for the provider
# - name: name of member
# - remember_token: session token
#
# == Associations
#
# === Belongs to:
# - OldMember
#
# === Has Many:
# - CommitteeMember
# - Committee
# - TablingSlotMember
# - TablingSlot
# - Commitment
# - CommitmentCalendar
# - EventMember
# - Reimbursement


class Member < ActiveRecord::Base
  attr_accessible :name, :provider, :uid,   
    :profile, :old_member_id, :remember_token, 
    :confirmation_status, :swipy_data, :registration_comment,
    :commitments

  serialize :commitments # array of length 168 for all hours in a week. 1 if busy 0 if not

  validates :provider, :uid, :name, presence: true

  before_create :create_remember_token

  has_many :tabling_slot_members, dependent: :destroy
  has_many :tabling_slots, through: :tabling_slot_members

  # join member and committee table with join table
  has_and_belongs_to_many :committees, join_table: 'committee_members'

  # should be able to easily access members committee information
  has_many :committee_members, dependent: :destroy
  has_many :committees, through: :committee_members

  # commitments should not be nil and should be a 168 length array of 1 and 0
  validates :commitments, presence: true
  validate :commitments_must_be_168_array
  before_validation :default_commitments

  has_many :event_members, dependent: :destroy


  """ 
  convenince methods for the Member class 
  these can be called like Member.member_hash or Member.current_members
  """

   def self.member_hash
    mhash = Rails.cache.read('member_hash')
    if mhash == nil
      mhash = Member.all.index_by(&:id)
      Rails.cache.write('member_hash', mhash)
    end
    return mhash
  end

  def self.current_members_dict(semester = Semester.current_semester)
    mdict = Rails.cache.read('current_members_dict')
    if mdict != nil
      return mdict
    end

    current_members = self.current_members(semester)
    mdict = current_members.index_by(&:id)
    Rails.cache.write('current_members_dict', mdict)
    return mdict
  end

  def self.members_chart(semester = Semester.current_semester)
    records = Rails.cache.read('members_chart')
    if records != nil
      return records
    end

    sql_query = "SELECT 
      m.name as name, 
      m.email as email,
      c.name as committee,
      c.id as committee_id,
      m.id as member_id
      FROM members as m
      JOIN committee_members as cm ON m.id = cm.member_id
      JOIN committees as c ON cm.committee_id = c.id
      WHERE cm.semester_id = " + Semester.current_semester.id.to_s+" ORDER BY c.name"

    records = ActiveRecord::Base.connection.execute(sql_query).to_a
    Rails.cache.write('member_chart', records)
    return records
  end

  #
  # returns all alum (people who aren't in a committee this semester). GM committee is 1
  #
  def self.alumni
    in_a_committee_ids = CommitteeMember.where(semester: Semester.current_semester).pluck(:member_id)
    return Member.where('id NOT IN (?)', in_a_committee_ids)
  end

  def self.currently_in_committee(committee, semester = Semester.current_semester)
    # cms = Member.where(committees)
    current_committee_members = CommitteeMember.where(semester_id: semester.id).where(committee_id: committee.id).pluck(:member_id)
    return Member.where('id IN (?)', current_committee_members)
  end

  def self.current_gm_ids(semester = Semester.current_semester)
    gm_id = Committee.find(1)
    gm_ids = CommitteeMember.where(committee_id: gm_id).where(semester_id: semester.id).pluck(:member_id)
  end

  # excludes gms
  def self.current_members(semester = Semester.current_semester)
    current_committee_member_ids = CommitteeMember.where(semester_id: semester.id).pluck(:member_id)
    return Member.where('id IN (?)', current_committee_member_ids).where('id NOT IN (?)', Member.current_gm_ids)
  end

  # chairs and execs
  def self.current_officers(semester = Semester.current_semester)
    chair_ids = CommitteeMember.where(semester: semester).where('position_id > 2').pluck(:member_id)
    return Member.where('id IN (?)', chair_ids)
  end

  def self.current_execs(semester = Semester.current_semester)
    chair_ids = CommitteeMember.where(semester: semester).where('position_id = 4').pluck(:member_id)
    return Member.where('id IN (?)', chair_ids)
  end

  def self.current_chairs(semester = Semester.current_semester)
    chair_ids = CommitteeMember.where(semester: semester).where('position_id = 3').pluck(:member_id)
    return Member.where('id IN (?)', chair_ids)
  end

  # excludes chairs
  def self.current_cms(semester = Semester.current_semester)
    # chair_exec_tier = CommitteeMemberType.where("tier > 1").pluck(:id)
    # chair_ids = CommitteeMember.where(semester: semester).where('committee_member_type_id IN (?)', chair_exec_tier).pluck(:member_id)
    current_committee_member_ids = CommitteeMember.where(semester_id: semester.id).where('position_id = 2').pluck(:member_id)
    return Member.where('id IN (?)', current_committee_member_ids)#.where('id NOT IN (?)', Member.current_gm_ids).where('id NOT IN (?)', chair_ids)
  end

""" Convenience Methods (API) """
# returns the committee for this semester and gm if not in any committee
  def current_committee(semester = Semester.current_semester)
    cm = CommitteeMember.where('member_id = ? AND semester_id = ?', self.id, semester.id)
    if cm.length == 0
      return Committee.gm
    else
      return Committee.find(cm.first.committee_id)
    end
  end

  def position(semester = Semester.current_semester)
    committee = self.current_committee
    if committee == Committee.gm 
      return CommitteeMemberPosition.positions[1]
    else
      return CommitteeMember.where('member_id = ? AND semester_id = ? AND committee_id = ?', self.id, semester.id, committee.id).first.position
    end
  end

  def primary_committee
    self.committees.first
  end

  def role(semester = Semester.current_semester)
    return self.position(semester).name 
  end

  def tier(semester = Semester.current_semester)
    return self.position(semester).tier
  end

  def permissions(semester = Semester.current_semester)
    return self.position(semester).permissions
  end

  # execs and web development are considered admin
  def admin?
    if self.name == 'David Liu' or self.name == 'Eric Quach'
      return true
    end
    return (self.position.permissions == 3 or self.current_committee == Committee.wd)
     #or self.committees.include?(Committee.where(name: "Executive").first)
  end

  def exec?
    self.tier == 3
  end

  # Officer status of the member.
  def officer?
    self.tier >= 2
  end

  """ end of API methods (only the methods above are 'supported') """

  # returns url of profile image. if none return path to blank.png
  def profile_url
    if self.profile and self.profile != ""
      return self.profile
    else
      gravatar_id = Digest::MD5.hexdigest(self.email.downcase)
      return "http://gravatar.com/avatar/#{gravatar_id}.png"
    end

  end

  # Ininialize itself with some OmniAuth information
  #
  # === Parameters
  # - provider: the authentication service provider
  # - uid: the ID of the member under the provider
  def self.initialize_with_omniauth(provider, uid)
    Member.where(provider: provider, uid: uid).first_or_initialize
  end

  # The other Members that are part of this member's committees
  def cms(semester = Semester.current_semester)
    mem_ids = self.current_committee.cms.pluck(:member_id)
    return Member.where('id IN (?)', mem_ids)
  end

  # Create a new session token.
  def Member.new_remember_token
    SecureRandom.urlsafe_base64
  end

  # Encrypt the token.
  def Member.encrypt(token)
    Digest::SHA1.hexdigest(token.to_s)
  end


  def attended_events(semester = Semester.current_semester)
    # p EventMember.where(member_id: self.id).length
    begin
      event_ids = EventMember.where(member_id: self.id).pluck(:event_id)
      return Event.where('id IN (?)', event_ids)
    rescue
      p 'failed'
    end
  end

  #
  # for each event add boolean for attended or not
  #
  def attendance_mapping(events)
    attended_ids = self.attended_events.pluck(:id)
    return events.map{|e| attended_ids.include? e.id}
  end

  #
  # for each event adds id of event if attended or nil if not
  #
  def attendance_id_mapping(events)
    attended_ids = self.attended_events.pluck(:id)
    return events.map{|e| {'id'=>e.id,'attended'=> (attended_ids.include? e.id ) }}
  end

  # Checks attendance for an event.
  #
  # === Parameters
  # - event: an event with an id
  def attended?(event)
    !self.event_members.where(event_id: event.id).empty?
  end

  #
  # update member based on secretary's approval
  #
  def update_from_secretary(committee, position_id, position_name)
    committee_type = CommitteeType.committee
    if position_id == 0
      committee_type = CommitteeType.general
      cm_type = CommitteeMemberType.gm
    elsif position_id == 1
      committee_type = CommitteeType.committee
      cm_type = CommitteeMemberType.cm
    elsif position_id == 2
      committee_type = CommitteeType.committee
      cm_type = CommitteeMemberType.chair
    elsif position_id == 3
      committee_type = CommitteeType.admin
      cm_type = CommitteeMemberType.exec(position_name)
    end
    self.add_to_committee(committee.name, committee_type, cm_type)
  end



  # Add member to the committee (creating the committee if it doesn't exist) as the given
  # committee member type, if he isn't part of the committee already
  # TODO semester?
  def add_to_committee(committee_name, committee_type, cm_type, semester = Semester.current_semester)
    # Find or create committee
    committee = Committee.where(
      name: committee_name,
    ).first_or_create!

    # Set the committee type
    committee.committee_type = committee_type
    committee.save!

    # remove self from current committees (david)
    self.committee_members.where(
      # committee_id: committee.id,
      semester_id: semester.id,
    ).destroy_all

    # Add member to committee if not already
    committee_member = self.committee_members.where(
      committee_id: committee.id,
      semester_id: semester.id,
    ).first_or_create!

    # Set the committee_member type
    committee_member.committee_member_type = cm_type
    committee_member.save!
  end

  # Remove from the general committee, if put in a regular committee.
  # Done by default when adding to a regular committee.
  def remove_from_general
    # Get general committees (may be more than one)
    general = Committee.where(
      committee_type_id: CommitteeType.general.id
    )

    # If this member is in the general members group (tested using set difference)
    if (general - self.committees).empty?
      general.each do |committee|
        self.committees.delete(general)
      end
    end
  end

  # Calculate the total number of points this member has
  def total_points(semester = Semester.current_semester)
    if semester == 'all'
      curr_events = Event.pluck(:id).collect{|i| i.to_s}
    else
      curr_events = Event.where(semester: semester).pluck(:id).collect{|i| i.to_s}
    end
    # events = EventMember.joins('INNER JOIN events ON CAST(events.id AS varchar) = event_members.event_id').where(member_id: self.id).pluck(:event_id)
    events_attended = EventMember.where('event_id IN (?)', curr_events).where(member_id: self.id).pluck(:event_id)
    return EventPoints.where('event_id IN (?)', events_attended).sum(:value)
  end


  # Return all attended tabling slots
  def attended_slots
    return self.tabling_slot_members.where(status_id: Status.where(name: :attended).first).pluck(:tabling_slot)
  end

  private

    def create_remember_token
      self.remember_token = Member.encrypt(Member.new_remember_token)
    end

  """ validation """
  def default_commitments
    default_com = Array.new(168)
    168.times{|i| default_com[i] = 0}
    self.commitments ||= default_com
  end

  def commitments_must_be_168_array
    if self.commitments
      if self.commitments.kind_of?(Array)
        if self.commitments.all?{|i| i.is_a? Fixnum }
          if self.commitments.length == 168
            return
          else
          end
        end
      end
    end
    errors.add(:commitments, "commitments must be a 168 array")
    
  end

end
