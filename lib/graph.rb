class Graph

  def self.get_data_for_piechart params

    event_options = HashWithIndifferentAccess.new({
                                                      fields: ['count(magnitude) as mag', 'location_id'],
                                                      group: 'location_id'
                                                  })
    event_options.reverse_merge! params
    events = Event.get_events_for event_options

    scope = (params[:scope]=="state") ? "state" : "city || ', ' || state"
    loc_options = HashWithIndifferentAccess.new({
                                                    fields: ["#{scope} as scope", 'sum(subquery.mag) as grouped_mag']
                                                })
    loc_options.reverse_merge! params
    locs = Location.get_locs_for loc_options

    format_piechart(locs.joins("join (#{events.to_sql}) subquery on locations.id=subquery.location_id").group("scope").order("grouped_mag desc").limit(params[:pie_limit]))

  end

  def self.get_data_for_barchart params
    range = params[:upper_bound].to_i - params[:lower_bound].to_i
    if range-1 <= params[:bar_limit].to_i
      result = get_grouped_data_for_barchart params
    else
      result = get_bucketed_data_for_barchart params
    end

    format_barchart_data result
  end

  def self.get_grouped_data_for_barchart params
    params.reverse_merge! Event.defaults

    type_where = form_where_clause(params[:type])
    primary_where = form_where_clause(params[:primary_attribute])
    secondary_where = form_where_clause(params[:secondary_attribute])
    brand_where = form_where_clause(params[:brand])

    query = <<-END_SQL
          select magnitude as categories, sum(sq.data) as data from
            (select e.magnitude, count(e.id) as data from events e 
              join locations l on e.location_id = l.id 
              where l.lat between :south and :north 
              and l.long between :west and :east 
              and e.time_stamp between :start and :finish
              and e.magnitude between :lower_bound and :upper_bound
              and e.data_type #{type_where}
              and e.primary_attribute #{primary_where}
              and e.secondary_attribute #{secondary_where} 
              and e.brand_id #{brand_where}
              group by e.magnitude) sq
          group by magnitude
          order by magnitude;
    END_SQL

    Event.find_by_sql [query, params]
  end

  def self.get_bucketed_data_for_barchart params
 
    params[:range] = 1 + params[:upper_bound].to_i - params[:lower_bound].to_i
    params.reverse_merge! Event.defaults

    type_where = form_where_clause(params[:type])
    primary_where = form_where_clause(params[:primary_attribute])
    secondary_where = form_where_clause(params[:secondary_attribute])
    brand_where = form_where_clause(params[:brand])

    query = <<-END_SQL
          with intervals as (
          select
            n as start,
            LEAST(:upper_bound, (n  + :range / :bar_limit)) as end
            from generate_series(:lower_bound, :upper_bound-1, CEILING(:range::numeric / :bar_limit)::int) n
          )
          select concat(i.start, ' - ', i.end) as categories, sum(sq.data) as data from
            (select e.magnitude, count(e.id) as data from events e 
              join locations l on e.location_id = l.id 
              where l.lat between :south and :north 
              and l.long between :west and :east 
              and e.time_stamp between :start and :finish 
              and e.magnitude between :lower_bound and :upper_bound 
              and e.data_type #{type_where}
              and e.primary_attribute #{primary_where}
              and e.secondary_attribute #{secondary_where} 
              and e.brand_id #{brand_where}
              group by e.magnitude) sq
          right join intervals i on sq.magnitude between i.start and i.end
          group by i.start,i.end
          order by i.start;
    END_SQL

    Event.find_by_sql [query, params]
    #format_barchart_data(Event.find_by_sql([query, params]))

  end

  def self.get_data_for_areachart params

    params[:bucket_size] = (params[:finish]-params[:start])/params[:area_limit].to_f
    params.reverse_merge! Event.defaults
    params[:time_format] = "YYYY-MM-DD, FMHH:mm:ssAM"

    scope = (params[:scope]=="state") ? "state" : "city";
    primary_where = form_where_clause(params[:primary_attribute])
    secondary_where = form_where_clause(params[:secondary_attribute])
    type_where = form_where_clause(params[:type])
    brand_where = form_where_clause(params[:brand])
    query = <<-END_SQL
    with intervals as (
  select 
    (:start::timestamp + (interval '1 second' * n)) start_time,
    (:start::timestamp + (interval '1 second' * (n + :bucket_size))) end_time
    from generate_series(0, (extract('epoch' from 
            (timestamp :finish - timestamp :start)))::integer - :bucket_size::integer, 
            :bucket_size::integer) n 
  )

select to_char(i.start_time,:time_format) as categories, 
        sq.#{scope} as scope, sum(sq.data) as data 
        from (select l.#{scope}, e.time_stamp, count(e.id) as data 
          from events e join locations l on e.location_id = l.id 
          where l.lat between :south and :north 
          and l.long between :west and :east 
          and e.time_stamp between :start and :finish
          and e.magnitude between :lower_bound and :upper_bound
          and e.primary_attribute #{primary_where}
          and e.secondary_attribute #{secondary_where}
          and e.data_type #{type_where}
          and e.brand_id #{brand_where}
          group by e.time_stamp, l.#{scope}) sq 
          right join intervals i on sq.time_stamp between i.start_time and i.end_time 
          where sq.#{scope} in 
              (select ssq.#{scope} from (select l.#{scope}, sum(sssq.data) as count_data 
                from locations l join 
                  (select location_id, count(magnitude) as data 
                    from events where time_stamp between :start and :finish 
                    and magnitude between :lower_bound and :upper_bound
                    and primary_attribute #{primary_where}
                    and secondary_attribute #{secondary_where}
                    and data_type #{type_where}
                    and brand_id #{brand_where}
                    group by location_id) sssq 
                  on sssq.location_id=l.id 
                  where l.lat between :south and :north 
                  and l.long between :west and :east group by #{scope} order by count_data desc limit 5) ssq)
              group by i.start_time, sq.#{scope} order by i.start_time;

              END_SQL

    format_areachart_data Event.find_by_sql [query, params]

  end

  private
  def self.format_piechart(result_array)
    result_array.map do |result|
      [result['scope'], result['grouped_mag'].to_i]
    end
  end

  #converts array_of_attributes_hash to hash_of_attributes_array
  #where an attribute hash is a map of each result object's property,value pair
  def self.format_areachart_data(result_array)

    colors = ['#2f7ed8', '#0d233a', '#8bbc21', '#910000', '#1aadce', '#492970', '#f28f43', '#77a1e5', '#c42525', '#a6c96a']
    times_set = SortedSet.new
    scopes_set = Set.new

    result_array.each do |result|
      times_set.add result["categories"]
      scopes_set.add result["scope"]
    end
    returned_hash = {:categories => times_set.to_a}

    series_array = []
    scopes_set.each_with_index do |scope, index|
      series_array[index] = {:name => scope, :color => colors[index]}
      data_array = []
      times_set.each do |time|
        flag = 0
        result_array.each do |result|
          if result["scope"]==scope && result["categories"]==time
            data_array << result["data"].to_i
            flag = 1
          end
        end
        data_array << 0 if flag==0
      end
      series_array[index][:data] = data_array
    end

    returned_hash[:series] = series_array
    returned_hash
  end

  def self.format_barchart_data(result_array)
    colors = ['#2f7ed8', '#0d233a', '#8bbc21', '#910000', '#1aadce', '#492970', '#f28f43', '#77a1e5', '#c42525', '#a6c96a']
    color = 0
    has_data = false
    final_result = result_array.inject({}) do |hash_of_attributes_array, array_of_attributes_hash|
      array_of_attributes_hash.attributes.each_pair do |key, value|
        #adding 1 as Laplacian corrections for nil data
        if(key=='data')
          has_data = true unless value.to_i == 0
        end
        (hash_of_attributes_array[key] ||= []) << ((key=="data") ? {'y' => value.to_i, 'color' => colors[color]} : value)
        (color += 1) if(key=='data')
        color %= colors.length if(key=='data')
      end
      hash_of_attributes_array
    end
    index = 1
   if(has_data)
    final_result
    else
      []
    end
  end

  private
  def self.form_where_clause str_array
    if str_array.length==0
      "IS NULL"
    else
      "IN (#{(str_array.map{ |str| ActiveRecord::Base::sanitize str }).join(',')})"
    end
  end 

end
