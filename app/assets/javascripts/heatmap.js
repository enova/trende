window.HeatMap = {
  layer:  new google.maps.visualization.HeatmapLayer(),
  url:    "/map_data",

  initialize: function() {
    this.map = new google.maps.Map($('#map-canvas')[0], {
      zoom:             4,
      minZoom:          2,
      maxZoom:          11,
      center:           new google.maps.LatLng(39.8097,-98.5553),
      mapTypeId:        google.maps.MapTypeId.ROADMAP,
      styles:           [{ stylers: [{saturation: -75}]}, { featureType: 'poi.park', stylers: [{visibility: 'off'}]}]
    });
    this.layer.setMap(this.map);

  },

  geocode: function(geocode_place) {
    console.log('geocoding ' + geocode_place);
    $('#geocode').val(geocode_place);
    $.getJSON('/geocode', {place: geocode_place}, function(data){
      if(data==0) {
        $('#geocode').fadeOut(200).fadeIn(200);
        return;
      }
      var ne = data['northeast']
      var sw = data['southwest']
      var neb = new google.maps.LatLng(ne['lat'], ne['lng']);
      var swb = new google.maps.LatLng(sw['lat'], sw['lng']);
      console.log('('+ne['lat']+', '+ne['lng']+', '+sw['lat']+', '+sw['lng']+')');

      var bounds = new google.maps.LatLngBounds()
      bounds.extend(neb);
      bounds.extend(swb);
      HeatMap.map.fitBounds(bounds);
      OptionsPane.update_recent_locations(geocode_place);
    });
  },

  populate_heatmap: function(points) {
    $('#loading').fadeOut();

    HeatMap.layer.setData(
      points.map(function(point) {return {
        location: new google.maps.LatLng(point[0], point[1]),
        weight: point[2]
      }})
      );
  },

  bounds: function(dir) {
    var bounds    = this.map.getBounds();
    var northeast = bounds.getNorthEast();
    var southwest = bounds.getSouthWest();

    switch(dir) {
      case 'north': return northeast.lat();
      case 'east':  return northeast.lng();
      case 'south': return southwest.lat();
      case 'west':  return southwest.lng();
      default: return null;
    }
  },

  refresh: function() {
    clearTimeout(HeatMap.refreshTimeout);
    HeatMap.refreshTimeout = setTimeout(function(){
      if(!OptionsPane.bound_check()) return;
      $('#loading').fadeIn();
      $.getJSON(HeatMap.url, HeatMap.values(), HeatMap.populate_heatmap);
    }, 200);

  },
  values: function() {
    return {
      zoom:  HeatMap.map.getZoom(),
      north: HeatMap.bounds('north'),
      east:  HeatMap.bounds('east'),
      south: HeatMap.bounds('south'),
      west:  HeatMap.bounds('west'),
      start: $('#start_date').val(),
      finish: $('#end_date').val(),
      scope: (HeatMap.map.getZoom() > 5 ? 'city' : 'state'),
      type: $('#type').val(),
      primary_attribute: $('#primary_attribute').val(),
      secondary_attribute: $('#secondary_attribute').val(),
      lower_bound: $('#lower_bound').val(),
      upper_bound: $('#upper_bound').val(),
      brand: $('#brand').val()
    }
  }
};

function refresh_all() {
	window.time = new Date().getTime();
	HeatMap.refresh();
    Graphs.refresh_visible_graph();
	setTimeout(OptionsPane.autoRefresh,10000);
}


$(function(){
  HeatMap.initialize();
  Graphs.initialize();
  OptionsPane.initialize();
  TabbedPane.initialize_buttons();
  window.time = new Date().getTime();

  HeatMap.map.addListener('bounds_changed', refresh_all);
  setTimeout(OptionsPane.autoRefresh, 10000);
});
