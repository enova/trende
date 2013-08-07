window.HeatMap = {
  extractionSize: null,
  moviePointer: 0,
  moviePoints: [],
  layers: [new google.maps.visualization.HeatmapLayer()],
  url: "/map_data",

  initialize: function() {
    this.map = new google.maps.Map($('#map-canvas')[0], {
      zoom:             4,
      minZoom:          2,
      maxZoom:          11,
      center:           new google.maps.LatLng(39.8097,-98.5553),
      mapTypeId:        google.maps.MapTypeId.ROADMAP,
      styles:           [{ stylers: [{saturation: -75}]}, { featureType: 'poi.park', stylers: [{visibility: 'off'}]}]
    });
    this.currentLayer().setMap(this.map);
  },

  currentLayer:  function(){
      return this.layers[this.layers.length - 1]
  },

  geocode: function(geocode_place) {
    console.log('geocoding ' + geocode_place);
    $('#geocode').val(geocode_place);
    $.getJSON('/geocode', {place: geocode_place}, function(data){
      if(data==0) {
        $('#geocode').fadeOut(200).fadeIn(200).fadeOut(200).fadeIn(200);
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
    HeatMap.extractionSize = null;
    HeatMap.moviePointer = 0;
    HeatMap.moviePoints = [];
    HeatMap.currentLayer().setData(
      points.map(function(point) {return {
        location: new google.maps.LatLng(point[0], point[1]),
        weight: point[2]
      }})
      );
  },

  movie: function() {
    HeatMap.extractionSize = HeatMap.extractionSize == null? window.defaultExtractionSize : HeatMap.extractionSize;
    if (HeatMap.moviePointer < HeatMap.moviePoints.length - 1) {
        HeatMap.moviePoints.slice(HeatMap.moviePointer,HeatMap.moviePointer+HeatMap.extractionSize).map(function(point) {
            return {
              location: new google.maps.LatLng(point[0], point[1]),
              weight: point[2]
            }
        }).map(function (i) {
          window.movieArray.push(i);
        });
      $('#movie_div').html(HeatMap.moviePoints[Math.round(HeatMap.moviePointer+(HeatMap.extractionSize/2))][3]);
      HeatMap.moviePointer = HeatMap.moviePointer + HeatMap.extractionSize;
      HeatMap.nextClip = setTimeout(function(){HeatMap.movie()}, 30);
    }
    else {
        HeatMap.extractionSize = null;
        HeatMap.moviePointer = 0;
        HeatMap.moviePoints = [];
        setTimeout(function(){
            $('#movie_div').empty();
            $('#delete_layer, #play_pause_div, #forward_div, #back_div').hide();
            $('#movie_div').css('bottom', '30px').css('right', '32px');
            $('#movie_div').css('background', "url('/assets/play.png') no-repeat 0px 0px");
            $('#movie_div').addClass('clickable');
        },1000);
    }
  },

  addLayer: function(){
    if(!OptionsPane.bound_check()) return;
    $('#loading').fadeIn();
    this.layers.push(new google.maps.visualization.HeatmapLayer());
    this.currentLayer().setMap(this.map);
    $('#loading').fadeOut();
  },

  removeCurrentLayer: function(){
      if(!OptionsPane.bound_check()) return;
      $('#loading').fadeIn();
      this.currentLayer().setMap(null);
      this.layers.pop();
      $('#loading').fadeOut();
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
    clearTimeout(HeatMap.nextClip);
    HeatMap.extractionSize = null;
    HeatMap.moviePointer = 0;
    HeatMap.moviePoints = [];
    setTimeout(function(){
      $('#movie_div').empty();
      $('#delete_layer, #play_pause_div, #forward_div, #back_div').hide();
      $('#movie_div').css('bottom', '30px').css('right', '32px');
      $('#movie_div').css('background', "url('/assets/play.png') no-repeat 0px 0px");
      $('#movie_div').addClass('clickable');
    },1000);
    HeatMap.refreshTimeout = setTimeout(function(){
      if(!OptionsPane.bound_check()) return;
      if(HeatMap.layers.length < 1) return;
      $('#loading').fadeIn();
      $.getJSON(HeatMap.url, HeatMap.values(), function(points){
          HeatMap.populate_heatmap(points);
      });
    }, 100);

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
  },

  movie_values: function() {
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
        brand: $('#brand').val(),
        group: "movie"
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
  heatmap = HeatMap;
  setTimeout(OptionsPane.autoRefresh, 10000);
});

$(document).ready(function(){
    $('#opacity_slider').slider({
        min:0,
        max:100,
        animate:"fast",
        slide: function( event, ui ) {
            HeatMap.currentLayer().setOptions({opacity: $("#opacity_slider").slider("value")/100});
        }
    });
    $('#radius_slider').slider({
        min:0,
        max:20,
        animate:"fast",
        slide: function( event, ui ) {
            HeatMap.currentLayer().setOptions({radius: $("#radius_slider").slider("value")});
        }
    });
    $('#intensity_slider').slider({
        min:1,
        max:500,
        step: 1,
        animate:"fast",
        slide: function( event, ui ) {
            HeatMap.currentLayer().setOptions({maxIntensity: $("#intensity_slider").slider("value") * 1000});
        }
    });

    $("#color_picker1, #color_picker2, #color_picker3").spectrum({
        color: "red",
        preferredFormat: "rgb",
        move: function(color) {
            HeatMap.currentLayer().setOptions({gradient: makeSmoothGradient()});
        }
    });

    function makeSmoothGradient(){
        return ['rgba(' + $('#color_picker3').spectrum("get").toRgb().r + ',' + $('#color_picker3').spectrum("get").toRgb().g + ',' + $('#color_picker3').spectrum("get").toRgb().b + ',' + 0 + ')',
                'rgba(' + $('#color_picker3').spectrum("get").toRgb().r + ',' + $('#color_picker3').spectrum("get").toRgb().g + ',' + $('#color_picker3').spectrum("get").toRgb().b + ',' + 1 + ')',
                'rgba(' + $('#color_picker2').spectrum("get").toRgb().r + ',' + $('#color_picker2').spectrum("get").toRgb().g + ',' + $('#color_picker2').spectrum("get").toRgb().b + ',' + 1 + ')',
                'rgba(' + $('#color_picker1').spectrum("get").toRgb().r + ',' + $('#color_picker1').spectrum("get").toRgb().g + ',' + $('#color_picker1').spectrum("get").toRgb().b + ',' + 1 + ')'];
    }

    $( "#opacity_slider" ).slider( "value", 70);
    $( "#radius_slider" ).slider( "value", 10);
    $( "#intensity_slider" ).slider( "value", 100);

    $('#new_layer').on('click', function(){
        heatmap.addLayer();
        if (heatmap.layers.length == 3) {
            $('#new_layer').hide();
        }
        if (heatmap.layers.length > 1) {
            $('#delete_layer').show();
        }
    });
    $('#delete_layer').on('click', function(){
        heatmap.removeCurrentLayer();
        if (heatmap.layers.length < 3) {
            $('#new_layer').show();
        }
        if (heatmap.layers.length == 1) {
            $('#delete_layer').hide();
        }
    });
    $('#movie_div').on('click', function(){
        if ($('#movie_div').hasClass('clickable')) {
            $('#movie_div').removeClass('clickable');
            $('#loading').fadeIn();
            $.getJSON(HeatMap.url, HeatMap.movie_values(), function(points){
                window.movieArray = new google.maps.MVCArray();
                if (points%100 != 0) {
                    points.splice(points.length - points.length%100);
                }
                HeatMap.moviePoints = points;
                window.defaultExtractionSize = Math.round(HeatMap.moviePoints.length / 100);
                HeatMap.currentLayer().setData(window.movieArray);
                HeatMap.currentLayer().setOptions({radius: 5, maxIntensity: 34000});
                $('#loading').fadeOut();
                $('#movie_div').css('bottom', '60px').css('right', '125px');
                $('#movie_div').css('background', 'none');
                $('#play_pause_div').css('bottom', '30px').css('right', '73px').addClass("playing");
                $('#forward_div').css('bottom', '30px').css('right', '25px');
                $('#back_div').css('bottom', '30px').css('right', '116px');
                $('#play_pause_div, #forward_div, #back_div').show();
                HeatMap.movie();
            });
        }
    });
    $('#show_hide_controls').on('click', function(){
        $('#layer_controls').fadeToggle();
        $('#map_controls').fadeToggle();
    });
    $('#play_pause_div').on('click', function(){
        if ($('#play_pause_div').hasClass("playing")) {
            clearTimeout(HeatMap.nextClip);
            $('#play_pause_div').removeClass("playing").addClass("paused");
            $('#play_pause_div').css('background-image', "url('/assets/play.png')");
        }else if ($('#play_pause_div').hasClass("paused")) {
            $('#play_pause_div').removeClass("paused").addClass("playing");
            HeatMap.nextClip = setTimeout(HeatMap.movie, 30);
            $('#play_pause_div').css('background-image', "url('/assets/pause.png')");
        } else {}
    });
    $('#forward_div').on('click', function(){
        //TODO: clear timeout if exists to avoid race
        if (HeatMap.moviePointer < HeatMap.moviePoints.length - 1) {
            HeatMap.moviePoints.slice(HeatMap.moviePointer,HeatMap.moviePointer+HeatMap.extractionSize).map(function(point) {
                return {
                    location: new google.maps.LatLng(point[0], point[1]),
                    weight: point[2]
                }
            }).map(function (i) {
                    window.movieArray.push(i);
                });
          $('#movie_div').html(HeatMap.moviePoints[Math.round(HeatMap.moviePointer+(HeatMap.extractionSize/2))][3]);
          HeatMap.moviePointer = HeatMap.moviePointer + HeatMap.extractionSize;
        } else {
            HeatMap.extractionSize = null;
            HeatMap.moviePointer = 0;
            HeatMap.moviePoints = [];
            setTimeout(function(){
                $('#movie_div').empty();
                $('#delete_layer, #play_pause_div, #forward_div, #back_div').hide();
                $('#movie_div').css('bottom', '30px').css('right', '32px');
                $('#movie_div').css('background', "url('/assets/play.png') no-repeat 0px 0px");
                $('#movie_div').addClass('clickable');
            },1000);
        }
        //TODO: reset timeout if existed to avoid race
    });
    $('#back_div').on('click', function(){
        //TODO: clear timeout if exists to avoid race
        if (HeatMap.moviePointer > 0) {
            HeatMap.moviePointer = HeatMap.moviePointer - HeatMap.extractionSize;
            for(var i = HeatMap.extractionSize; i > 0; i--) {
                window.movieArray.pop();
            }
            $('#movie_div').html(HeatMap.moviePoints[Math.round(HeatMap.moviePointer+(HeatMap.extractionSize/2))][3]);
        }
        //TODO: reset timeout if existed to avoid race
    });
    $('#forward_div').mousehold(function() {
        $('#forward_div').click();
    }, 200);
    $('#back_div').mousehold(function() {
        $('#back_div').click();
    }, 200);
    $('#delete_layer, #play_pause_div, #forward_div, #back_div, #layer_controls, #map_controls').hide();
    $("#new_layer").tooltip({ items: '#new_layer', content : 'Add new heatmap layer', track: 'true'});
    $("#delete_layer").tooltip({ items: '#delete_layer', content : 'Delete latest heatmap layer', track: 'true'});
    $("#opacity_slider").tooltip({ items: '#opacity_slider', content : function() {return 'Current Layer Opacity: ' + $('#opacity_slider').slider("value")}, track: 'true', open: function( event, ui ) {
            setTimeout(function(){$( "#opacity_slider" ).tooltip( "close" )},7500)
        }
    });
    $("#radius_slider").tooltip({ items: '#radius_slider', content : function() {return 'Current Layer Radius: ' + $('#radius_slider').slider("value")}, track: 'true', open: function( event, ui ) {
            setTimeout(function(){$( "#radius_slider" ).tooltip( "close" )},7500)
        }
    });
    $("#intensity_slider").tooltip({ items: '#intensity_slider', content : function() {return 'Current Layer Intensity: ' + $('#intensity_slider').slider("value")}, track: 'true', open: function( event, ui ) {
            setTimeout(function(){$( "#intensity_slider" ).tooltip( "close" )},7500)
        }
    });
});
