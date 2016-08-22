# == Schema Information
#
# Table name: jobs
#
#  id           :integer          not null, primary key
#  created_at   :datetime
#  updated_at   :datetime
#  project_id   :integer          not null
#  locked_by    :string(255)
#  locked_at    :datetime
#  started_at   :datetime
#  completed_at :datetime
#  created_by   :string(255)
#  task         :string(255)      not null
#  args         :binary
#  status       :string(255)
#  error        :text
#  progress     :integer          default(0)
#

class Job < ApplicationRecord

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

        $stderr.puts "Errors: #{record.errors.map{|x| x.inspect}}"

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

  validates_presence_of :project_id

  # Allow the base Job class to be used for Dial Jobs
  attr_accessor :range
  attr_accessor :range_file
  attr_accessor :lines
  attr_accessor :seconds
  attr_accessor :cid_mask

  attr_accessor :scope
  attr_accessor :force
  attr_accessor :target_id
  attr_accessor :target_ids

  validates_with JobValidator

  def stop
    self.class.where(id: self.id).update_all(status: 'cancelled')
  end

  def update_progress(pct)
    if pct >= 100
      self.class.where(id: self.id).update_all(:progress => pct, :completed_at => Time.now, :status => 'completed')
    else
      self.class.where(id: self.id).update_all(:progress => pct)
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

      return self.save

    when 'analysis'
      self.status = 'submitted'
      d = {
                                :scope      => self.scope,          # job / project/ global
                                :force      => !!(self.force),      # true / false
                                :target_id  => self.target_id.to_i, # job_id or project_id or nil
                                :target_ids => (self.target_ids || []).map{|x| x.to_i }
                        }
      $stderr.puts d.inspect

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

  def rate
    tend = (self.completed_at || Time.now)
    tlen = tend.to_f - self.started_at.to_f

    case self.task
    when 'dialer'
      Call.where('job_id = ?', self.id).count() / tlen
    when 'analysis'
      Call.where('job_id = ? AND analysis_completed_at > ? AND analysis_completed_at < ?', self.details[:target_id], self.created_at, tend).count() / tlen
    when 'import'
      Call.where('job_id = ?', self.id).count() / tlen
    else
      0
    end
  end

end
