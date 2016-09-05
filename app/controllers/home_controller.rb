class HomeController < ApplicationController

  def index

  end

  def about
    begin
      @has_kissfft = "MISSING"
      require 'kissfft'
      @has_kissfft = $LOADED_FEATURES.grep(/kissfft/)[0]
    rescue ::LoadError
    end
  end

  def help
  end

  def check
    @has_project  = ( Project.count > 0 )
    @has_provider = ( Provider.where(enabled: true).count > 0 )
    @has_job      = ( Job.where(task: 'dialer').count > 0 )
    @has_result   = ( Call.where(answered: true ).count > 0 )
    @has_analysis = ( Call.where('analysis_completed_at IS NOT NULL').count > 0 )
  end

end
