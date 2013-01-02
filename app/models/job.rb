class Job < ActiveRecord::Base

	class JobValidator < ActiveModel::Validator
		def validate(record)
			case record.task
			when 'dialer'

				cracked_range = WarVOX::Phone.crack_mask(record.range) rescue []
				unless cracked_range.length > 0
					record.errors[:range] << "No valid ranges were specified"
				end

				cracked_mask = WarVOX::Phone.crack_mask(record.cid_mask) rescue []
				unless cracked_mask.length > 0
					record.errors[:cid_mask] << "No valid Caller ID mask was specified"
				end

				unless record.seconds.to_i > 0 and record.seconds.to_i < 300
					record.errors[:seconds] << "Seconds should be between 1 and 300"
				end

				unless record.lines.to_i > 0 and record.lines.to_i < 10000
					record.errors[:lines] << "Lines should be between 1 and 10,000"
				end
			when 'analysis'
			when 'import'
			else
				record.errors[:base] << "Invalid task specified"
			end
		end
	end


	has_many :calls
	belongs_to :project
	validates_with JobValidator

	def stop
		self.class.update_all({ :status => 'cancelled'}, { :id => self.id })
	end

	def update_progress(pct)
		if pct >= 100
			self.class.update_all({ :progress => pct, :completed_at => Time.now.utc, :status => 'completed' }, { :id => self.id })
		else
			self.class.update_all({ :progress => pct }, { :id => self.id })
		end
	end


	validates_presence_of :project_id

	attr_accessible :project_id


	# Allow the base Job class to be used for Dial Jobs
	attr_accessor :range
	attr_accessor :range_file
	attr_accessor :lines
	attr_accessor :seconds
	attr_accessor :cid_mask

	attr_accessible :range, :seconds, :lines, :cid_mask


	def schedule
		case task
		when 'dialer'
			self.status = 'submitted'
			self.args   = Marshal.dump({
				:range    => self.range,
				:lines    => self.lines.to_i,
				:seconds  => self.seconds.to_i,
				:cid_mask => self.cid_mask
			})
			return self.save
		when 'analysis'
			#
		else
			raise ::RuntimeError, "Unsupported Job type"
		end
	end

end
