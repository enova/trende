class Map

  def self.get_points_for_heatmap params
    time_format = false
    event_options = HashWithIndifferentAccess.new({
      fields: ['sum(magnitude) as mag', 'location_id'],
      group: ['location_id']
    })

    loc_options = HashWithIndifferentAccess.new({
      fields: ['lat','long','subquery.mag']
    })

    if params[:group] == 'movie'
      params.reject! do |key|
        key == :group
      end
      grouping_granularity = params[:finish] - params[:start] > 2637000 ? 'week' : 'day'
      event_options[:group].push("date_trunc( '#{grouping_granularity}', time_stamp )")
      event_options[:fields].push("date_trunc( '#{grouping_granularity}', time_stamp ) as time")
      loc_options[:fields].push('subquery.time')
      loc_options[:order] = 'time'
      time_format = '%Y, %b/%d'
    end

    event_options.reverse_merge! params
    loc_options.reverse_merge! params

    events = Event.get_events_for event_options
    locs = Location.get_locs_for loc_options

    format_data(locs.joins("join (#{events.to_sql}) subquery on locations.id=subquery.location_id"), time_format)

  end

  private
  def self.format_data(result_array, time_format)
    result_array.map do |p|
      if time_format
        [p.lat.to_f, p.long.to_f, p.mag.to_i, Time.parse(p.time).strftime(time_format)]
      else
        [p.lat.to_f, p.long.to_f, p.mag.to_i]
      end
    end
  end

end
