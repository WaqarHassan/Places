class Place
	# include ActiveModel::Model
	attr_accessor :id , :formatted_address , :location , :address_components
	def initialize params = {}
		@id = params[:_id].nil? ? params[:id] : params[:_id].to_s
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
		collection.insert_many( data)
	end
	def self.find_by_short_name short_name
		collection.find({'address_components.short_name': short_name })
	end
	def self.to_places view
		place = []
		view.each do |v|
			place <<  Place.new(v)
		end
		place
	end
	def self.find id
		result = collection.find({_id: BSON::ObjectId.from_string(id)}).first
		result = Place.new(result) if !result.nil?

	end
	def self.all offset = 0 , limit = 0
		result = []
		collection.find.skip(offset).limit(limit).each do |r|
			result << Place.new(r)
		end
		result
	end
	def destroy
		self.class.collection.find({_id: BSON::ObjectId(@id)}).delete_one
	end		
	def self.get_address_components(sort = {}, offset = 0, limit = nil)
    queries = [ {:$project => {_id: 1, address_components: 1, formatted_address: 1, :'geometry.geolocation' => 1}}, 
                              {:$unwind => '$address_components'}, {:$skip => offset}]  
    queries.insert(2, {:$sort => sort}) if sort != {}
    queries << {:$limit => limit} if !limit.nil?
    collection.find.aggregate(queries)
  end
  def self.get_country_names
  	# collection.aggregate([{:$unwind => }])
  	collection.aggregate([
  		{:$unwind => '$address_components'},
  		{:$match => {'address_components.types' => 'country'}},
  		{:$group => {:_id => '$address_components.long_name'}},
  		{:$project => {:_id => 1}}
  			]).to_a.map{|a| a[:_id]}

  end
  def self.find_ids_by_country_code country_code
  	collection.aggregate([ 
  		{:$match => {'address_components.short_name' => country_code}}, 
  	  {:$project => {:_id => 1}}
  	  ]).to_a.map{|a| a[:_id].to_s}
  end




end