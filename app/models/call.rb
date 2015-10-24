# == Schema Information
#
# Table name: calls
#
#  id                    :integer          not null, primary key
#  created_at            :datetime
#  updated_at            :datetime
#  number                :text             not null
#  project_id            :integer          not null
#  job_id                :integer          not null
#  provider_id           :integer          not null
#  answered              :boolean
#  busy                  :boolean
#  error                 :text
#  audio_length          :integer
#  ring_length           :integer
#  caller_id             :text
#  analysis_job_id       :integer
#  analysis_started_at   :datetime
#  analysis_completed_at :datetime
#  peak_freq             :float
#  peak_freq_data        :text
#  line_type             :text
#  fprint                :integer          is an Array
#

class Call < ActiveRecord::Base

  reportable :hourly, :aggregation => :count, :grouping => :hour, :live_data => true, :cacheable => false, :limit => 24
  reportable :daily, :aggregation => :count, :grouping => :day, :live_data => true, :cacheable => false, :limit => 7
  reportable :weekly, :aggregation => :count, :grouping => :week, :live_data => true, :cacheable => false, :limit => 52
  reportable :monthly, :aggregation => :count, :grouping => :month, :live_data => true, :cacheable => false, :limit => 12

  reportable :analyzed_hourly, :aggregation => :count, :grouping => :hour, :date_column => :analysis_completed_at, :live_data => true, :cacheable => false, :limit => 24
  reportable :analyzed_daily, :aggregation => :count, :grouping => :day, :date_column => :analysis_completed_at, :live_data => true, :cacheable => false, :limit => 7
  reportable :analyzed_weekly, :aggregation => :count, :grouping => :week, :date_column => :analysis_completed_at, :live_data => true, :cacheable => false, :limit => 52
  reportable :analyzed_monthly, :aggregation => :count, :grouping => :month, :date_column => :analysis_completed_at, :live_data => true, :cacheable => false, :limit => 12

  belongs_to :project
  belongs_to :provider
  belongs_to :job
  has_one :call_medium, :dependent => :delete

  def matches
    #    "AND (( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & calls.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}'::int[])::float ) * 100.0 ) > 10.0 " +
    self.find_by_sql([
      'SELECT calls.*,  ' +
      "  (( icount(ARRAY[?]::int[] & calls.fprint::int[]) / icount(ARRAY[?]::int[])::float ) * 100.0 ) AS matchscore " +
      'FROM calls ' +
      'WHERE icount(calls.fprint) > 0 AND ' +
      "calls.job_id = ? AND " +
      "calls.id != ? " +
      'ORDER BY matchscore DESC',
      fprint_map,
      fprint_map,
      self.job_id,
      self.id
      ])
  end

  def matches_all_jobs

    #    "AND (( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & calls.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}'::int[])::float ) * 100.0 ) > 10.0 " +
    self.find_by_sql([
      'SELECT calls.*,  ' +
      "  (( icount(ARRAY[?]::int[] & calls.fprint::int[]) / icount(ARRAY[?]::int[])::float ) * 100.0 ) AS matchscore " +
      'FROM calls ' +
      'WHERE icount(calls.fprint) > 0 AND ' +
      "calls.id != ? " +
      'ORDER BY matchscore DESC',
      fprint,
      fprint,
      self.id
      ])
  end

  after_save :update_linked_line

  def paginate_matches(scope, min_match, page, per_page)

    match_sql =
      'SELECT calls.*,  ' +
      "  (( icount(ARRAY[?]::int[] & calls.fprint::int[]) / icount(ARRAY[?]::int[])::float ) * 100.0 ) AS matchscore " +
      'FROM calls ' +
      'WHERE icount(calls.fprint) > 0 AND '
    args = [fprint, fprint]

    case scope
    when 'job'
      match_sql << " calls.job_id = ? AND "
      args << job.id.to_i
    when 'project'
      match_sql << " calls.project_id = ? AND "
      args << project_id.to_i
    end

    match_sql << "calls.id != ? "
    args << self.id

    match_sql << " AND (( icount(ARRAY[?]::int[] & calls.fprint::int[]) / icount(ARRAY[?]::int[])::float ) * 100.0 ) > ? ORDER BY matchscore DESC"
    args << fprint
    args << fprint
    args << min_match.to_f

    query = [match_sql, *args]
    Call.paginate_by_sql(query, :page => page, :per_page => per_page)
  end

  def media
    CallMedium.where(call_id: self.id, project_id: self.project_id).first_or_create
  end

  def media_fields
    CallMedium.columns_hash.keys.reject{|x| x =~ /^id|_id$/}
  end

  def linked_line
    Line.where(number: self.number, project_id: self.project_id).first_or_create
  end

  def update_linked_line
    line = linked_line

    if self[:line_type]
      line.line_type = self[:line_type]
      line.save
    end
  end

end
