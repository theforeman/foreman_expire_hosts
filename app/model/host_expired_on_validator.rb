module HostExpiredOnValidator

	extend ActiveSupport::Concern
	
	included do
		after_validation :validate_expired_on
	end

	def validate_expired_on		
		if Host.column_names.include?("expired_on")
			if (SETTINGS[:host_expired_on] and SETTINGS[:host_expired_on][:host_form] and SETTINGS[:host_expired_on][:host_form][:is_mandatory]) and self.expired_on.to_s.blank?
				errors.add(:expired_on, "can't be blank and must be future date")
			end
			if !self.expired_on.to_s.blank?
				begin
					unless expired_on.to_s.to_date > Date.today
						errors.add(:expired_on, "must be future date")
					end
				rescue Exception => e
					errors.add(:expired_on, "invalid date")
				end
			end
			if self.changed.include?("expired_on")
				unless can_modify_expiry_date?
					errors.add(:expired_on, "no permission to edit")
				end
			end			
			return errors[:expired_on].empty?
		end
	end

	def can_modify_expiry_date?
		can_owner_modify  = SETTINGS[:host_expired_on].try(:fetch, :edit_expiry_field).try(:fetch, :can_owner_modify) rescue false
		return ( new_record? or (User.current and (User.current.admin or (can_owner_modify.to_s.downcase == 'true' and ((owner_type == "User" and owner.id == User.current.id) or (owner_type == "Usergroup" and owner.users.map{|usr| usr.id}.include?(User.current.id)) )))))
	end
end