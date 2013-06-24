window.Graphs = {
  current_pie_limit: 8,
  current_bar_limit: 6,
  current_area_limit: 5,

  refresh_pie_graph: function (pie_data, limit){

    $('#pie_graph').highcharts({
      chart: { type: 'pie' },
      title: { text: 'Event Volume by Location' },
      subtitle: { text: 'Top '+limit+' in this view'},
      series: [{
        type: 'pie',
        name: 'Volume',
        data: pie_data
      }],
      tooltip: { valueSuffix: ' events' },
      plotOptions:{  pie:{ size: 350 } },
      credits: { enabled: false }
    });
  },
  refresh_bar_graph: function (bar_data, limit) {
   $('#bar_graph').highcharts({
      chart: { type: 'column' },
      title: { text: 'Event Volume by Magnitude' },
      subtitle: { text: 'Top '+limit+' in this view'},
      xAxis: {
        categories: bar_data['categories'],
        labels: {
          rotation: -45,
          align: 'right',
          style: {
            fontSize: '13px',
            fontFamily: 'Verdana, sans-serif'
          }
        },
        title: {
          text: 'Magnitude',
          align: 'middle',
        },
      },
      yAxis: {
        min: 0,
        labels: { overflow: 'justify' },
        title: {
          text: 'Number of Events',
          align: 'middle',
        },
      },
      plotOptions: {
        column: { dataLabels: { inside: false, enabled: true, color: 'white' } } ,
        series: {  stacking: 'normal' }
      },
      legend: { enabled: false },
      credits: { enabled: false },
      series: [{
        name: 'count',
        data: bar_data['data'],
        dataLabels: {
          enabled: true,
          rotation: -90,
          color: '#FFFFFF',
          align: 'right',
          x: 4,
          y: 10,
          style: {
            fontSize: '13px',
            fontFamily: 'Verdana, sans-serif'
          }
        }}]
    });
  },
  refresh_area_graph: function (area_data, limit) {
    $('#area_graph').highcharts({
      chart: { type: 'areaspline' },
      title: { text: 'Event Volume Over Time' },
      subtitle: { text: 'Top '+limit+' in this view'},
      legend:{ enabled: true },
      xAxis: {
        categories: area_data["categories"],
        labels: {
          rotation: -45,
          align: 'right'
        }
      },
      yAxis: { title: { text: 'Number of Events' } },
      tooltip: {
        shared: true,
        valueSuffix: ' loans'
      },
      credits: { enabled: false },
      plotOptions: { areaspline: { fillOpacity: 0.5 } },
      series: area_data["series"]
    });
  },

  is_valid: function(data) {
    return !(data === undefined  || data.length == 0
          || (data['data'] !== undefined && data['data'].length == 0)
          || (data['series']!==undefined && data['series'].length == 0));
  },

  refresh_visible_graph: function () {
    clearTimeout(Graphs.refreshTimeout);
    Graphs.refreshTimeout = setTimeout( function() {

      if(!OptionsPane.bound_check()) return;
      $('.overlay').fadeIn();
      $('#meter').fadeIn();
      $('#no_data').fadeOut();
      var type = TabbedPane.get_selected_type();
      var options = $.extend(true, HeatMap.values(), Graphs.get_limits());
      $.getJSON('/'+type+'_data', options, function(data) {

        if(!Graphs.is_valid(data)) $('#no_data').fadeIn();

        switch(type){
          case 'pie':
            Graphs.refresh_pie_graph(data, options.pie_limit);
            Graphs.update_wedge_map(data);
            break;
          case 'bar':
            Graphs.refresh_bar_graph(data, options.bar_limit);
            Graphs.update_bar_map(data['categories']);
            break;
          case 'area':
            Graphs.refresh_area_graph(data, options.area_limit);
            break;
          case 'none': break;
        }
        if(Graphs.is_valid(data)){
          $('.overlay').fadeOut();
          $('#no_data').fadeOut();
        }
        $('#map_overlay').fadeOut();
        $('#meter').fadeOut();
        if (type == "pie"){
          Graphs.update_wedge_map(data);
        };
      });
    }, 400);
  },


  update_wedge_map: function(places){
    var children = $('.highcharts-series').children();
    for(var c = children.length/2, i=0 ; c < children.length; c++, i++){
      $(children[c]).data('place', places[i][0]);
      $(children[c]).click(Graphs.handle_wedge_click);
    }
  },
  update_bar_map: function(ranges){
    var children = $('.highcharts-series').children();
    for(var c = 0; c < children.length; c++){
      console.log(ranges[c]);
      $(children[c]).data('range', ranges[c]);
      $(children[c]).click(Graphs.handle_bar_click);
    }
  },

  handle_wedge_click: function (event) {
    HeatMap.geocode($(event.target).data('place'));
  },

  handle_bar_click: function (event) {
    var min_max = $(event.target).data('range').split(' - ');
    $('#lower_bound').val(parseInt(min_max[0]));
    $('#upper_bound').val(parseInt(min_max[1]));
    refresh_all();
  },

  get_limits: function() {
    return {
      pie_limit: Graphs.current_pie_limit,
      bar_limit: Graphs.current_bar_limit,
      area_limit: Graphs.current_area_limit
    }
  },

  handle_limit_change: function(event) {
    var type = TabbedPane.get_selected_type();
    var moved_to =$(event.target).slider('value');

    if( Graphs['current_'+type+'_limit'] != moved_to) {
      Graphs.refresh_visible_graph();
      Graphs['current_'+type+'_limit'] = moved_to;
    }
  },

  create_chart: function(id_prefix, max_limit) {
    $chart_slider_div = $('<div>');
    $chart_slider_div.addClass('white_shadowed_box');
    $chart = $('<div>');
    $chart.addClass('graph');
    $chart.attr('id', id_prefix+'_graph');

    $label_slider_div = $('<div>')
    $label = $('<label>').html('Num. Displayed: ');
    $label.addClass('slider_label span2');

    $slider = $('<div>');
    $slider.attr('id', id_prefix+"_slider");
    $slider.addClass('slider ui-slider-range span10');
    $slider.slider({
      orientation: "horizontal",
      range: "max",
      max: max_limit,
      min: 3,
      step: 1,
      value: Graphs['current_'+id_prefix+'_limit'],
      slide: function(event, ui) {
        $('.ui-slider-handle').text(ui.value);
      },
      change: Graphs.handle_limit_change
    });

    $label_slider_div.append($label);
    $label_slider_div.append($slider)

    $chart_slider_div.append($chart);
    $chart_slider_div.append($label_slider_div);

    return $chart_slider_div;
  },

  /*
  * To add a new type of chart:
  * (1) Graphs.<id_prefix>_chart = Graphs.create_chart (<id_prefix>, upper_limit)
  * (2) Create a refresh_<id_prefix_graph() function that accepts data
  * (3) Map it to a button in gselect.js
  * (4) Add a 'case' statement for the refresh function in refresh_visible_graph
  * (5) Add a namespaced variable called Graphs.current_<id_prefix>_limit that is accessible in get_limits
  */
  initialize: function() {
    Graphs.pie_chart = Graphs.create_chart('pie', 15);
    Graphs.bar_chart = Graphs.create_chart('bar', 10);
    Graphs.area_chart = Graphs.create_chart('area', 10);

    $graph_overlay = $('<div>')
        .addClass('overlay')
        .attr('id', 'graph_overlay');
    $map_overlay = $('<div>')
        .addClass('overlay')
        .attr('id', 'map_overlay');
    $meter = $('<img>')
        .attr('id', 'meter')
        .attr('src', '/assets/378.gif');
    $no_data = $('<p>')
        .attr('id', 'no_data')
        .html('No data');
    $('#visualization')
        .append(Graphs.pie_chart)
        .append($graph_overlay)
        .append($meter)
        .append($no_data);
    $('#map')
        .append($map_overlay)
        .append($('#loading_div'));
  }
}
