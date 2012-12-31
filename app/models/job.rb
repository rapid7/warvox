class Job < ActiveRecord::Base
	has_many :calls
	belongs_to :project

	def update_progress(pct)
		if pct >= 100
			self.class.update_all({ :progress => pct, :completed_at => Time.now.utc }, { :id => self.id })
		else
			self.class.update_all({ :progress => pct }, { :id => self.id })
		end
	end
end
