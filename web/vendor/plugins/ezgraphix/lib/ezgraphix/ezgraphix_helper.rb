module EzgraphixHelper
  #method used in ActionView::Base to render graphics.
  def render_ezgraphix(g)
    result = ""
    html = Builder::XmlMarkup.new(:target => result)
    html.div("test", :id => g.div_name)
    html = Builder::XmlMarkup.new(:target => result)
    html.script(:type => 'text/javascript') do
      html << "var ezChart = new FusionCharts('#{f_type(g.c_type)}','#{g.div_name}','#{g.w}','#{g.h}','0','0');\n"
      html << "ezChart.setDataXML(\"#{g.to_xml}\");\n" unless g.data.is_a?(String)
      html << "ezChart.setDataURL(\"#{g.data}\");\n" if g.data.is_a?(String)
      html << "ezChart.render(\"#{g.div_name}\");\n"
    end
    result
  end

  def f_type(c_type)
    case c_type
    when 'area2d'
      '/FusionCharts/FCF_Area2D.swf'
    when 'col3d'
      '/FusionCharts/FCF_Column3D.swf'
    when 'bar2d'
      '/FusionCharts/FCF_Bar2D.swf'
    when 'barline3d'
      '/FusionCharts/FCF_MSColumn3DLineDY.swf'
    when 'col2d'
      '/FusionCharts/FCF_Column2D.swf'
    when 'pie2d'
      '/FusionCharts/FCF_Pie2D.swf'
    when 'pie3d'
      '/FusionCharts/FCF_Pie3D.swf'
    when 'line'
      '/FusionCharts/FCF_Line.swf'
    when 'doug2d'
      '/FusionCharts/FCF_Doughnut2D.swf'
    when 'msline'
      '/FusionCharts/FCF_MSLine.swf'
    when 'mscol3d'
      '/FusionCharts/FCF_MSColumn3D.swf'
    when 'mscol2d'
      '/FusionCharts/FCF_MSColumn2D.swf'
    when 'msarea2d'
      '/FusionCharts/FCF_MSArea2D.swf'
    when 'msbar2d'
      '/FusionCharts/FCF_MSBar2D.swf'
    end
  end

  def parse_options(options)
    original_names = Hash.new

    options.each{|k,v|
      case k
      when :animation
        original_names['animation'] = v
      when :y_name
        original_names['yAxisName'] = v
      when :caption
        original_names['caption'] = v
      when :subcaption
        original_names['subCaption'] = v
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
      when :show_column_shadow
        original_names['showColumnShadow'] = v
      end
      }
    original_names
  end
end
