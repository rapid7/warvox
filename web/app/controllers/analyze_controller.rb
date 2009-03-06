class AnalyzeController < ApplicationController
  layout 'warvox'
  
  def index
	@jobs = DialJob.paginate_all_by_processed(
		true,
		:page => params[:page], 
		:order => 'id DESC',
		:per_page => 30
	)
  end

  def view
  	@job_id = params[:id]
	@results = DialResult.paginate_all_by_dial_job_id(
		@job_id,
		:page => params[:page], 
		:order => 'number ASC',
		:per_page => 10,
		:conditions => [ 'completed = ? and processed = ? and busy = ?', true, true, false ]
	)


	@g1 = Ezgraphix::Graphic.new(:c_type => 'col3d', :div_name => 'calls_pie1')
	@g1.render_options(:caption => 'Detected Lines by Type', :y_name => 'Lines', :w => 700, :h => 300)

	ltypes = DialResult.find( :all, :select => 'DISTINCT line_type' ).map{|r| r.line_type}
	res_types = {}

	ltypes.each do |k|
		next if not k
		res_types[k.capitalize.to_sym] = DialResult.count(
			:conditions => ['dial_job_id = ? and line_type = ?', @job_id, k]
		)
	end
	
	@g1.data = res_types
  end

  # GET /dial_results/1/resource?id=XXX&type=YYY
  def resource
  	ctype = 'text/html'
	cpath = nil
	
	res = DialResult.find(params[:result_id])
	if(res and res.processed and res.rawfile)
		case params[:type]
		when 'big_sig'
			ctype = 'image/png'
			cpath = res.rawfile.gsub(/\..*/, '') + '_big.png'
		when 'big_sig_dots'
			ctype = 'image/png'
			cpath = res.rawfile.gsub(/\..*/, '') + '_big_dots.png'	
		when 'small_sig'
			ctype = 'image/png'
			cpath = res.rawfile.gsub(/\..*/, '') + '.png'
		when 'mp3'
			ctype = 'audio/mpeg'
			cpath = res.rawfile.gsub(/\..*/, '') + '.mp3'
		when 'sig'
			ctype = 'text/plain'
			cpath = res.rawfile.gsub(/\..*/, '') + '.sig'
		when 'raw'
			ctype = 'octet/binary-stream'
			cpath = res.rawfile
		when 'big_freq'
			ctype = 'image/png'
			cpath = res.rawfile.gsub(/\..*/, '') + '_freq_big.png'	
		when 'small_freq'
			ctype = 'image/png'
			cpath = res.rawfile.gsub(/\..*/, '') + '_freq.png'			
		end
	end
	
	cdata = "File not found"
	if(cpath and File.readable?(cpath))
		cdata = File.read(cpath, File.size(cpath))
	end
	
    send_data(cdata, :type => ctype, :disposition => 'inline')
  end
end
