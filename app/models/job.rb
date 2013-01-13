class Job < ActiveRecord::Base

	reportable :hourly, :aggregation => :count, :grouping => :hour, :date_column => :created_at, :cacheable => false
	reportable :daily, :aggregation => :count, :grouping => :day, :date_column => :created_at, :cacheable => false
	reportable :weeky, :aggregation => :count, :grouping => :week, :date_column => :created_at, :cacheable => false
	reportable :monthly, :aggregation => :count, :grouping => :month, :date_column => :created_at, :cacheable => false

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
				unless ['calls', 'job', 'project', 'global'].include?(record.scope)
					record.errors[:scope] << "Scope must be calls, job, project, or global"
				end
				if record.scope == "job" and Job.where(:id => record.target_id.to_i, :task => ['import', 'dialer']).count == 0
					record.errors[:job_id] << "The job_id is not valid"
				end
				if record.scope == "project" and Project.where(:id => record.target_id.to_i).count == 0
					record.errors[:project_id] << "The project_id is not valid"
				end
				if record.scope == "calls" and (record.target_ids.nil? or record.target_ids.length == 0)
					record.errors[:target_ids] << "The target_ids list is empty"
				end
			when 'import'
			else
				record.errors[:base] << "Invalid task specified"
			end
		end
	end


	# XXX: Purging a single job will be slow, but deleting the project is fast
	has_many :calls, :dependent => :destroy

	belongs_to :project

	attr_accessible :task, :status, :progress

	validates_presence_of :project_id

	attr_accessible :project_id


	# Allow the base Job class to be used for Dial Jobs
	attr_accessor :range
	attr_accessor :range_file
	attr_accessor :lines
	attr_accessor :seconds
	attr_accessor :cid_mask

	attr_accessible :range, :seconds, :lines, :cid_mask

	attr_accessor :scope
	attr_accessor :force
	attr_accessor :target_id
	attr_accessor :target_ids

	attr_accessible :scope, :force, :target_id, :target_ids


	validates_with JobValidator

	def stop
		self.class.update_all({ :status => 'cancelled'}, { :id => self.id })
	end

	def update_progress(pct)
		if pct >= 100
			self.class.update_all({ :progress => pct, :completed_at => Time.now, :status => 'completed' }, { :id => self.id })
		else
			self.class.update_all({ :progress => pct }, { :id => self.id })
		end
	end

	def details
		Marshal.load(self.args) rescue {}
	end

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
			$stderr.puts self.inspect

			return self.save
		when 'analysis'
			self.status = 'submitted'
			self.args = Marshal.dump({
				:scope      => self.scope,          # job / project/ global
				:force      => !!(self.force),      # true / false
				:target_id  => self.target_id.to_i, # job_id or project_id or nil
				:target_ids => (self.target_ids || []).map{|x| x.to_i }
			})
			return self.save
		else
			raise ::RuntimeError, "Unsupported Job type"
		end
	end

end
