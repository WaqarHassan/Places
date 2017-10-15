class Photo

	def self.mongo_client
		Mongoid::Clients.default
	end
	attr_accessor :id , :location , :contents
end