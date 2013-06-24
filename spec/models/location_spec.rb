require 'spec_helper'

describe Location do

  miami = ["Miami"]
  chicago = ["Chicago"]
  dateline_cities = ["Anchorage","Sydney"]
  chicago_ny = ["Chicago","New York"]

  before :all do
    Location.delete_all
    Location.create(city: "Chicago", lat: 40.0, long: -90.0)
    Location.create(city: "New York", lat: 40.0, long: -75.0)
    Location.create(city: "Miami", lat: 25.0, long: -80.0)
    Location.create(city: "Anchorage", lat: 60.0, long: -150)
    Location.create(city: "Sydney", lat: -33.0, long: 150)
  end

  it "selects cities between latitudes" do
    cities(Location.bound_lat(20.0,30.0)).should =~ miami
  end

  it "selects cities between longitudes" do
    cities(Location.bound_long(-100.0,-85.0)).should =~ chicago
  end

  it "takes strings as input for long" do
    cities(Location.bound_long("-100.0", "-85.0")).should =~ chicago
  end

  it "takes strings as input for lat" do
    cities(Location.bound_lat("20.0","30.0")).should =~ miami
  end

  it "handles the dateline" do
    cities(Location.bound_long(140,-140)).should =~ dateline_cities
  end

  it "chains lat and long bounds" do
    cities(Location.bound_long(-90.0,-70.0).bound_lat(30.0,50.0)).should =~ chicago_ny
  end

private
  def cities array
    array.map { |i| i.city }
  end

end
