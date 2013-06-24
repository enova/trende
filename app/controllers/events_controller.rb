require 'chronic'
class EventsController < ApplicationController

  respond_to :json
 
  before_filter :parse_dates

  def map_data
    respond_with Map.get_points_for_heatmap params
  end

  def pie_data
    respond_with Graph.get_data_for_piechart params
  end

  def bar_data
    respond_with Graph.get_data_for_barchart params
  end

  def area_data
    respond_with Graph.get_data_for_areachart params
  end

private
  def parse_dates
    params[:start] = (Chronic.parse params[:start])
    params[:finish] = (Chronic.parse params[:finish])
    if (params[:start].nil? || params[:start] < Time.at(0) || params[:finish].nil? || params[:finish] < Time.at(0))
      params[:start] = Time.at(0)
      params[:finish] = Time.at(0)
    end
  end
end
