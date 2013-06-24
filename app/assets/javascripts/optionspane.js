window.OptionsPane = {

	initialize : function () {
    	$('#settings_button').click(function (event) {
        $('#settings_form').slideToggle('slow');
      });

	    //id's are keys from filters hash
	    $('#primary_attribute, #secondary_attribute, #type, #brand').on('change', refresh_all);

      $('#filters').submit(function(){
        console.log("refreshing");
        refresh_all();
      });

	    $('#lower_bound, #upper_bound').on('change', function(event) {
	        refresh_all();
	    });

	    $('#start_date_input, #end_date_input').datetimepicker({
       language: 'en', pick12HourFormat: true
     	});

      $('#start_date_input').on('changeDate', function(event) {
       $('#start_date').val($('#hidden_start_date').val());
       console.log("start date changed");
       refresh_all();
      });

      $('#end_date_input').on('changeDate', function(event) {
       $('#end_date').val($('#hidden_end_date').val());
       refresh_all();
      });

      $('#start_date, #end_date').on('change', refresh_all);
      $("select").multiselect({
          selectedList: 10
      });

	    $('#geocode_form').submit(function(e) {
	    	e.preventDefault();
        if(!OptionsPane.bound_check()) return;
        var loc = $('#geocode').val();
        if(loc != ""){
  	      HeatMap.geocode(loc);
        }
	    });

      $('body').on("click", '.location', function(e){
        if(!$(event.target).hasClass('cancel_button')){
          $('.active').removeClass("active");
          $(event.target).addClass('active');
          HeatMap.geocode($(e.target).attr('data-location'));
        }
        else  {
          $(event.target).parent().fadeOut('fast');
          $(event.target).parent().detach();
        }
      });

      $('#auto_refresh').click(function(e){
        if ($('#end_date').attr('disabled')) {
          $('#end_date').removeAttr('disabled');
          $('#end_button').fadeIn();
        }
        else {
          $('#end_date').attr('disabled', 'disabled');
          $('#end_button').fadeOut();
        }
      });

      $('.location:not(.pinned)').append(
          $('<img>').attr('src', '/assets/cancel.png')
              .addClass('cancel_button')
      );

	},

  bound_check: function() {
    if (parseInt($('#lower_bound').val()) <= parseInt($('#upper_bound').val())) {
       $('#lower_bound_group').css('background','none');
       return true;
    }
    else {
      $('#lower_bound_group').css('background','red')
        .fadeOut(200)
        .fadeIn(200);
       return false;
    }
  },

  update_recent_locations: function(location) {
    $('.active').removeClass("active");

    var length = $('.location').length;
    for(var i = 0; i < length; i++){
      var matches = /[^<]+/.exec($('.location')[i].innerHTML.toLowerCase());
      var already_listed = (matches === null ? false : matches[0].toLowerCase()===location.toLowerCase());

      if(already_listed) {
        $($('.location')[i]).addClass('active');
        return;
      }
    }

     $new_child = $('<li>')
                .addClass('location active')
                .attr('data-location',location)
                .html(location)
                .append(
                    $('<img>')
                    .attr('src', '/assets/cancel.png')
                    .addClass('cancel_button')
                  );

    $('.latest_locations').append($new_child);
    $new_child.show('slow')

    var last = $('li:last-child');
    while((last.position()['left'] + last.width() > 680) || $('.latest_locations').height() > 40) {
      $($('ul li:nth-child(3)')[0]).toggle('slow').remove();
    }
  },

autoRefresh: function() {
    var refresh_checked = $('#auto_refresh').prop('checked');
    if (refresh_checked && new Date().getTime() - window.time > 900000){
      formattedNow = formatDate(new Date());
      $('#end_date').val(formattedNow);
      refresh_all();
    } else {
      setTimeout(OptionsPane.autoRefresh, 10000);
    }
  }

};

function isNumberKey(evt){
  var charCode = (evt.which) ? evt.which : event.keyCode;
  return  (!(charCode < 48 || charCode > 57) || charCode == 13);
}


function formatDate(date)
{
  var year = date.getFullYear();
  var month = (date.getMonth()+1);
  var day = date.getDate();
  if (month < 10) {month = "0"+month;}
  if (day < 10) {day = "0"+day;}

  var hours = date.getHours();
  var minutes = date.getMinutes();
  if (hours < 10) {hours = "0"+hours;}
  if (minutes < 10) {minutes = "0"+minutes;}

  return year + '-' + month + '-' + day + ' ' + hours + ':' + minutes;
}
