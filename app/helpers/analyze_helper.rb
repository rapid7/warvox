module AnalyzeHelper


def fwd_match_html(pct)
	%Q|<span class="fwd_match_span" style='padding-right: 150px; border: 1px solid black; padding-left: 10px; padding-top: 3px; padding-bottom: 3px; background-color: #{pct_to_color(pct)}; color:white; font-weight: bold;'>
	
	#{"%.3f" % pct.to_f}% Match
	
	</span>
	
	|
end

def rev_match_html(pct)
	%Q|<span class="rev_match_span" style='padding-left: #{ (pct.to_i * 2).to_i }px; background-color: #{pct_to_color(pct)};'>#{pct}%</span>|
end

def pct_to_color(pct)
	"#" + "80" + (pct.to_i * 2.55).to_i.to_s(16).rjust(2, "0") + "80"
end

end
