class Point
	attr_accessor :latitude , :longitude
	
	def to_hash
		params = {}
		params[:type] = "Point"
		params[:coordinates] = [@longitude , @latitude]
		params
	end
	
	def initialize params ={}
		if !params.nil?
			if params[:type]
				@latitude = params[:coordinates][1]
				@longitude = params[:coordinates][0]
			else
				@latitude = params[:lat]
				@longitude = params[:lng]
			end		
		end
	end

end