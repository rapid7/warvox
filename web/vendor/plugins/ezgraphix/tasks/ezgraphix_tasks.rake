    namespace :ezgraphix do
    task :dir_setup do
      Dir.mkdir("#{RAILS_ROOT}/public/FusionCharts", 0700)
      puts "Created FusionCharts directory in public/"
    end
    
    task :cp_charts do
      FileUtils.cp_r("#{RAILS_ROOT}/vendor/plugins/ezgraphix/public/FusionCharts/", "#{RAILS_ROOT}/public/")
      puts "Charts copied."
    end
    
    task :cp_javascript do
      FileUtils.cp_r("#{RAILS_ROOT}/vendor/plugins/ezgraphix/public/javascripts/FusionCharts.js", "#{RAILS_ROOT}/public/javascripts/")
      puts "FusionCharts.js copied"
    end
      
    desc "Creates and copies all necessary files in order to use ezgraphix!"
    task :setup => [:dir_setup, :cp_charts, :cp_javascript]
  end