module AnalyzeHelper


def fwd_match_html(pct)
  %Q|<span class="badge fwd_match_span" style='background-color: #{pct_to_color(pct)};'>

  #{"%.3f" % pct.to_f}% Match

  </span>

  |
end

def rev_match_html(pct)
  %Q|<span class="rev_match_span" style='padding-left: #{ (pct.to_i * 2).to_i }px; background-color: #{pct_to_color(pct)};'>#{pct}%</span>|
end

def pct_to_color(pct)
  "#" + "20" + (pct.to_i * 2.00).to_i.to_s(16).rjust(2, "0") + "20"
end

end
