class Event < ActiveRecord::Base

  attr_accessible :time_stamp,:data_type,:primary_attribute,:secondary_attribute,:location_id,:magnitude

  belongs_to :location
  belongs_to :brand

  def self.date_between(start_date, end_date)
    where(:time_stamp => start_date..end_date)
  end

  def self.magnitude_between(lower_bound, upper_bound)
    where(:magnitude => lower_bound..upper_bound)
  end

  def self.type(type)
    where(:data_type => type)
  end

  def self.primary_attribute(primary_attribute)
    where(:primary_attribute => primary_attribute)
  end

  def self.secondary_attribute(secondary_attribute)
    where(:secondary_attribute => secondary_attribute)
  end

  def self.brand(brand)
    where(:brand_id => brand)
  end

  def self.get_filters
    { primary_attribute: get_primary_attributes,
      secondary_attribute: get_secondary_attributes,
      type: get_types }
  end

  def self.get_events_for options
    options.reverse_merge! defaults

    events = Event.date_between(options[:start], options[:finish])
    events = events.select(options[:fields]) unless options[:fields].nil?
    events = events.group(options[:group]) unless options[:fields].nil?
    events = events.magnitude_between(options[:lower_bound], options[:upper_bound])

    filtered_subquery = add_optional_filters(events, options)
  end

  private

  def self.get_types
    types = []
    Event.pluck('distinct data_type').each do |type|
      types << {name: type, value: type}
    end
    types
  end

  def self.get_primary_attributes
    attributes = []
    Event.pluck('distinct primary_attribute').each do |attribute|
      attributes << {name: attribute, value: attribute} 
    end
    attributes
  end

  def self.get_secondary_attributes
    attributes = []
    Event.pluck('distinct secondary_attribute').each do |attribute|
      attributes << {name: attribute, value: attribute}
    end
    attributes
  end

  def self.add_optional_filters(subquery, params)

    subquery = subquery.type(params[:type])
    subquery = subquery.primary_attribute(params[:primary_attribute])
    subquery = subquery.secondary_attribute(params[:secondary_attribute])
    subquery = subquery.brand(params[:brand])

    subquery

  end

  protected
  def self.defaults
    {
        start: "2013-03-01", finish: "2013-06-01",
        scope: "state", pie_limit: 10,
        bar_limit: 5,
        type: "all",
        primary_attribute: "all",
        secondary_attribute: "all",
        lower_bound: 0,
        upper_bound: 50000
    }
  end
end
