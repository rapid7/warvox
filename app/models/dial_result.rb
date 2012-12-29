class DialResult < ActiveRecord::Base
	belongs_to :provider
	belongs_to :dial_job
	has_one :dial_result_medium, :dependent => :delete

	has_many :matches, :class_name => 'DialResult', :finder_sql => proc {
		'SELECT dial_results.*,  ' +
		"	(( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & dial_results.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}'::int[])::float ) * 100.0 ) AS matchscore " +
		'FROM dial_results ' +
		'WHERE icount(dial_results.fprint) > 0 AND ' +
		"dial_results.dial_job_id = \'#{dial_job_id}\' AND " +
		"dial_results.id != \'#{id}\' " +
#		"AND (( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & dial_results.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}'::int[])::float ) * 100.0 ) > 10.0 " +
		'ORDER BY matchscore DESC'
	}

	has_many :matches_all_jobs, :class_name => 'DialResult', :finder_sql => proc {
		'SELECT dial_results.*,  ' +
		"	(( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & dial_results.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[])::float ) * 100.0 ) AS matchscore " +
		'FROM dial_results ' +
		'WHERE icount(dial_results.fprint) > 0 AND ' +
		"dial_results.id != \'#{id}\' " +
#		"AND (( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & dial_results.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}'::int[])::float ) * 100.0 ) > 10.0 " +
		'ORDER BY matchscore DESC'
	}


	def media
		DialResultMedium.find_or_create_by_dial_result_id(self[:id])
	end

	def media_fields
		DialResultMedium.columns_hash.keys.reject{|x| x =~ /^id|_id$/}
	end

end
