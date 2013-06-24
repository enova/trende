Trende::Application.routes.draw do

    root :to => 'dashboard#show'

    get "/map_data" => "events#map_data"
    get "/pie_data" => "events#pie_data"
    get "/bar_data" => "events#bar_data"
    get "/area_data" => "events#area_data"

    get "/geocode" => "geocode#geocode"
end
