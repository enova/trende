class Map

  def self.get_points_for_heatmap params

    event_options = HashWithIndifferentAccess.new({
      fields: ['sum(magnitude) as mag', 'location_id'],
      group: 'location_id'
    })
    event_options.reverse_merge! params
    events = Event.get_events_for event_options

    loc_options = HashWithIndifferentAccess.new({
      fields: ['lat','long','subquery.mag'] 
    })
    loc_options.reverse_merge! params
    locs = Location.get_locs_for loc_options

    format_data locs.joins("join (#{events.to_sql}) subquery on locations.id=subquery.location_id")

  end

  private
  def self.format_data(result_array)
    result_array.map do |p|
      [p.lat.to_f, p.long.to_f, p.mag.to_i]
    end
  end

end
