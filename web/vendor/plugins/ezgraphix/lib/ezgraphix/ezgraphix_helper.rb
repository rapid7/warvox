module EzgraphixHelper

  def get_style(g)
    case g.c_type
    when 'col3d'
      style = 'render_simple'
    when 'bar2d'
      style = 'render_simple'
    when 'col2d'
      style = 'render_simple'
    end
    style
  end
  
  #method used in ActionView::Base to render graphics.
  def render_ezgraphix(g)
    style = get_style(g)
    xml_data = g.to_xml
	%Q|
		<div id='#{g.div_name}'></div>
		<script type='text/javascript'>
			var ezChart = new FusionCharts('#{f_type(g.c_type)}', '#{g.div_name}', '#{g.w}', '#{g.h}','0','0');
			ezChart.setDataXML('#{g.to_xml.gsub('"', '&quot;')}');
			ezChart.render('#{g.div_name}');
		</script>	
	|
  end
  
  def f_type(c_type)
    type = ''
    case c_type
    when 'col3d'
      type = '/FusionCharts/FCF_Column3D.swf'
    when 'bar2d'
      type = '/FusionCharts/FCF_Bar2D.swf'
    when 'barline3d'
      type = '/FusionCharts/FCF_MSColumn3DLineDY.swf'
    when 'col2d'
      type = '/FusionCharts/FCF_Column2D.swf'
    when 'pie2d'
      type = '/FusionCharts/FCF_Pie2D.swf'
    when 'pie3d'
      type = '/FusionCharts/FCF_Pie3D.swf'
    when 'line'
      type = '/FusionCharts/FCF_Line.swf'
    when 'doug2d'
      type = '/FusionCharts/FCF_Doughnut2D.swf'
    end
  end
      
  def parse_options(options)
    original_names = Hash.new
    
    options.each{|k,v|
      case k 
      when :y_name
        original_names['yAxisName'] = v
      when :caption
        original_names['caption'] = v
      when :subcaption
        original_names['subCaptions'] = v
      when :prefix
        original_names['numberPrefix'] = v
      when :precision
        original_names['decimalPrecision'] = v
      when :div_line_precision
        original_names['divlinedecimalPrecision'] = v
      when :limits_precision
        original_names['limitsdecimalPrecision'] = v
      when :f_number
        original_names['formatNumber'] = v
      when :f_number_scale
        original_names['formatNumberScale'] = v
      when :rotate
        original_names['rotateNames']  = v  
      when :background
        original_names['bgColor'] = v
      when :line
        original_names['lineColor'] = v
      when :names
        original_names['showNames'] = v
      when :values
        original_names['showValues'] = v
      when :limits
        original_names['showLimits'] = v
      when :y_lines
        original_names['numdivlines'] = v
      when :p_y
        original_names['parentYAxis'] = v
      when :d_separator
        original_names['decimalSeparator'] = v
      when :t_separator
        original_name['thousandSeparator'] = v
      when :left_label_name
        original_names['PYAxisName'] = v
      when :right_label_name
        original_names['SYAxisName'] = v
      when :x_name
        original_names['xAxisName'] = v
      end
      }
    original_names
  end    
end
