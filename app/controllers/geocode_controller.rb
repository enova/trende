class GeocodeController < ApplicationController
 	respond_to :json

 	def geocode
 		loc = params[:place]
 		result = Geocoder.search(loc)

 		retval = ((result.nil? || result.empty?) ? 0 : result[0].geometry['viewport'])
 		respond_with retval
 	end
 end