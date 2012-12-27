class DialResult < ActiveRecord::Base
	belongs_to :provider
	belongs_to :dial_job


	has_many :matches, :class_name => 'DialResult', :finder_sql => proc {
		'SELECT dial_results.*,  ' +
		"	(( icount(\'#{fprint}\'::int[] & dial_results.fprint::int[]) / icount(\'#{fprint}\'::int[])::float ) * 100.0 ) AS matchscore " +
		'FROM dial_results ' +
		'WHERE icount(dial_results.fprint) > 0 AND ' +
		"dial_results.dial_job_id = \'#{dial_job_id}\' AND " +
		"dial_results.id != \'#{id}\' " +
		'ORDER BY matchscore DESC'
	}

	has_many :matches_all_jobs, :class_name => 'DialResult', :finder_sql => proc {
		'SELECT dial_results.*,  ' +
		"	(( icount(\'#{fprint}\'::int[] & dial_results.fprint::int[]) / icount(\'#{fprint}\'::int[])::float ) * 100.0 ) AS matchscore " +
		'FROM dial_results ' +
		'WHERE icount(dial_results.fprint) > 0 AND ' +
		"dial_results.id != \'#{id}\' " +
		'ORDER BY matchscore DESC'
	}
end
