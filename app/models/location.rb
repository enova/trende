class Location < ActiveRecord::Base
  attr_accessible :city, :lat, :long
  has_many :events

  def self.bound_lat(south, north)
    where(:lat => south..north)
  end

  def self.bound_long(west, east)
    if (west.to_f>east.to_f)
      where("long > ? or long < ?",west,east)
    else 
      where(:long => west..east)
    end
  end

  def self.get_locs_for options
    options.reverse_merge! defaults
    Location.select(options[:fields])
      .bound_lat(options[:south], options[:north])
      .bound_long(options[:west], options[:east])
  end

  protected
  def self.defaults
    {
      north: 59.0, east: -53.0,
      south: 13.0, west: -143.0
    }
  end

end
