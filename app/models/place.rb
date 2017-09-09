class Place
	# include ActiveModel::Model
	attr_accessor :id , :formatted_address , :location , :address_components
	def initialize params = {}
		@id = params[:_id].present? ? params[:_id].to_s : params[:id]
		@formatted_address = params[:formatted_address]
		@location = Point.new(params[:geometry][:geolocation])
		@address_components = params[:address_components].present? ? params[:address_components].map {|a|  AddressComponent.new(a) } : nil

	end
	def self.mongo_client
		 Mongoid::Clients.default
	end
	def self.collection
		self.mongo_client[:places]
	end
	def self.load_all io
		
		data = File.read io
		data = JSON.parse(data)
		# puts data
		collection.insert_many( data)
	end






end