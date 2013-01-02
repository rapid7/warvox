class LineAttribute < ActiveRecord::Base
	belongs_to :line
	belongs_to :project
end
