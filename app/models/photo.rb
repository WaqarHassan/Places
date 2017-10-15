class Photo

	def self.mongo_client
		Mongoid::Clients.default
	end
	attr_accessor :id , :location , :contents
	def initialize params = {}
		if !params.nil?
			@id = params[:_id].nil? ? params[:id] : params[:_id].to_s
			@location = Point.new(params[:metadata][:location]) if !params[:metadata].nil?
		else
			Photo.new
		end

	end
end