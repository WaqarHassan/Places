require 'exifr/jpeg'
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
	def persisted?
		!@id.nil?
	end
	def save
    if persisted?
      Rails.logger.debug {"Inside persisted"}
      updates = Hash.new()
      updates[:metadata] = {}
      updates[:metadata][:place] = @place
      updates[:metadata][:location] = @location.to_hash
      self.class.mongo_client.database.fs.find(_id: BSON::ObjectId(@id.to_s)).update_one(updates)
    else
      Rails.logger.debug {"saving gridfs file #{self.to_s}"}
      description = {}
      description[:filename] = @contents.to_s
      description[:content_type] = "image/jpeg"
      description[:metadata] = {}
      gps = EXIFR::JPEG.new(@contents).gps
      @contents.rewind
      @location = Point.new(lat: gps.latitude, lng: gps.longitude)
      description[:metadata][:location] = @location.to_hash 
      description[:metadata][:place] = BSON::ObjectId.from_string(@place.id.to_s) if !@place.nil?
      
      if @contents	
        Rails.logger.debug {"contents = #{@contents}"}
        grid_file = Mongo::Grid::File.new(@contents.read,description)
        @id = self.class.mongo_client.database.fs.insert_one(grid_file).to_s
      end
    end
    return @id
  end

  def self.all skip = 0 , limit= nil
  	photos = mongo_client.database.fs.find.skip(skip)
  	photos = photos.limit(limit) if !limit.nil?
  	photos.map{|p| Photo.new(p)}
  end
  def self.find id
  	
  	photo = mongo_client.database.fs.find(:_id => BSON::ObjectId(id)).first
  	# Photo.new(f)
  	return photo.nil? ? nil : Photo.new(f)
  end
  def contents
  	file = self.class.mongo_client.database.fs.find_one(:_id => BSON::ObjectId.from_string(@id.to_s))
  	size = ""
  	if file
  		file.chunks.reduce([]) do |e, chunk|
  			size << chunk.data.data
  		end
  	end
  	return size
  end
  
  # def destroy
  #   Rails.logger.debug {"Destroying file #{@id}"}
  #   self.class.mongo_client.database.fs.find(_id: BSON::ObjectId.from_string(@id)).delete_one
  # end
  def destroy
    Rails.logger.debug {"Destroying file #{@id}"}
	self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId(@id)).delete_one
  end
 
end