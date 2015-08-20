class MemberCommitment < ParseResource::Base
    fields :email, :commitments, :weekly_commitments

    #Randomly Generates weekly commitment row
    def self.generate_weekly_commitment
        MemberCommitment.destroy_all
        cms = ParseMember.current_members
        for cm in cms
            commitments = Array.new()
            tabling_commitments = Array.new()
            unvailable_times = Array.new()
            5.times do |i|
                tabling_commitments.push(rand(167)) 
            end
            rand(0..167).times do |j|
                commitments.push(rand(167))
            end
            commitment = MemberCommitment.new(
                email:cm.email,
                commitments: commitments,
                tabling_commitments: tabling_commitments,
            )
            commitment.save
        end
    end

    #Tallies commitment total and stores into hash
    def self.generate_commitments_tally
        members = MemberCommitment.all
        hash = Hash.new()
        for member in members
            member.commitments.each do |val|
                if (!hash.has_key?(val))
                    hash[val] = 1
                else
                    hash[val] += 1
                end
            end
        end
        return hash
    end

    #Gets recommend time slot based off of commitments tally.
    def self.get_recommended_slot(member)
        tally = self.generate_commitments_tally
        least_tally = tally.keys.sort{|a, b| tally[a] <=> tally[b]}
        recommended_val = least_tally[0]

        while member.commitments.include? recommended_val
            least_tally = least_tally.shift
            recommended_val = least_tally[0]
        end
        return recommended_val
    end

    #Replaces cannot attend slot with new slot
    def set_cannot_attend(email, slot)
         member = MemberCommitment.where(email: email).to_a[0]
         index = member.tabling_commitments.index(slot)
         member.tabling_commitments[index] = get_recommended_slot(member)
    end
end
