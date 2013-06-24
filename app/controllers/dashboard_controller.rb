class DashboardController < ApplicationController

  def show
    @filters = Event.get_filters
    @filters.merge! Brand.get_filters
  end

end
