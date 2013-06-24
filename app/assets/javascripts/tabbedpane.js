
window.TabbedPane = {
  button_map: {'Volume by Location': 'pie', 'Volume by Magnitude': 'bar', 'Volume by Time': 'area'},
  selected_button: 'Volume by Location',

    // Creates buttons in middle pane
    initialize_buttons: function() {
      $gselector = $('#graph_selector');
      var count = 0;
      for(key in TabbedPane.button_map) {
        $div = $('<div>')
        $div.attr('id', 'gb'+count);
        $div.addClass('graph_button span4');
        $div.html(key);
        $div.click(TabbedPane.switch_to_clicked);
        if(key == TabbedPane.selected_button) $div.addClass('selected');

        $gselector.append($div);
        count++;
      }
    },

    get_selected_type: function() {
      return TabbedPane.button_map[TabbedPane.selected_button];
    },

    toggle_selection: function(target) {
      // Reset background of all buttons to standard color
      $others = $('.graph_button');
      for(var i = 0; i < $others.length; i++) {
        $($others[i]).attr('class','graph_button span4');
      }

        // Then, 'highlight' selected button.
        var element = (target.attr('id') == undefined ? target.parent() : target.children());
        target.attr('class','graph_button span4 selected');
    },

    switch_to_clicked: function(event) {
      if(!OptionsPane.bound_check()) return;

      $target =  $(event.target);
      TabbedPane.toggle_selection($target);

      // If target id is undefined, then the text portion of the button was clicked.
      var html = $target.html();
      if(html != TabbedPane.selected_button) {

        var type = TabbedPane.button_map[html];
        var next_chart = Graphs[type+'_chart'];
        var last_type = TabbedPane.get_selected_type();
        var last_chart = Graphs[last_type+'_chart'];

        last_chart.detach();

        $('#visualization').append(next_chart);
        TabbedPane.selected_button = html;

        Graphs.refresh_visible_graph();
      }
   }
}
