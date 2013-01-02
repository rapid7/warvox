class Line < ActiveRecord::Base
	has_many :line_attributes, :dependent => :delete_all
	belongs_to :project

	def set_attribute(name, value, ctype='text/plain')
		la = LineAttribute.find_or_create_by_line_id_and_project_id_and_name(self[:id], self[:project_id], name)
		la.value = value
		la.ctype = ctype
		la.save
		la
	end

	def get_attribute(name)
		LineAttribute.where(:line_id => self[:id], :name => name).first
	end
end
