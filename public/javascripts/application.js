// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var controller = "/more";
var entries = new Array();
var entry_pos = -1;

$(document).ready(function() {

  $(window).infinitescroll({
      url: function(){ return controller; },
      appendTo: '#content'
  });

  $(window).keydown(function(event){
    switch (event.keyCode) {
      case 74: // j
        load_entries();
        scroll(true);
        break;

      case 75: // k
        scroll(false);
        break;
      
      // TODO: refactor around unobtrusive js, so this is less clumsy
      // this is pretty ugly right now. but it works!
      case 85:
        if (entries[entry_pos] !== undefined) {
          liked("#liked" + $(entries[entry_pos]).attr("value"));
        }
        break;

      case 78:
        if (entries[entry_pos] !== undefined) {
          disliked("#" + $(entries[entry_pos]).attr("value"));
        }
        break;
      }
  });


    navigation();

    enable_transition("/subscriptions/", "#subscriptions", false);
    enable_transition("/classifications/", "#classifications");
    enable_transition("/", "#home");

  });

function navigation()
{
  
  $("#next_entry").click(function(_event) {
    _event.preventDefault();

    load_entries();
    scroll(true);
  });

  $("#prev_entry").click(function (_event) {
    _event.preventDefault();

    scroll(false);
  });
}

function scroll(direction) {
  if(entries[entry_pos + direction] != undefined)  
  {
    if (direction) {
      read(entries[entry_pos]);
      dir = 1;
    }
    else {
      dir = -1;
    }
    
    entry_pos = entry_pos + dir;   
    $.scrollTo(entries[entry_pos], 300);
  }
}


function load_entries()
{
  entries = $(".entry").map(function() { return "#" + $(this).attr("id")}); 
  //return $("#entry_4412").nextAll(".entry").length;
}

function register_secondary_callbacks()
{
  enable_transition("/subscriptions/", ".subscription", true, true);
}

function enable_transition(kontroller, selector, endless, id)
{
  endless = typeof(endless) != 'undefined' ? endless : true;
  id = typeof(id) != 'undefined' ? id : false;

  if (endless) {
    kontroller = kontroller + "more/";
  }
  
  $(selector).click(function(e) {
    if (endless) {
      controller = kontroller;

      if (id) {
        kontroller = kontroller + $(this).attr("id");
        controller = kontroller;
      }
    }
    else {
      controller = "/nil";
    }

    e.preventDefault();
    $('#burden').fadeOut("fast", function(){
      $.get(kontroller, function(data, txt){
        $('#content').replaceWith(data);
        $('#burden').fadeIn("fast");

        // JQuery can't trace events for tags that don't exist in the DOM
        // onload. Now that we've loaded some more content, let's process
        // all of the callbacks that operate on this new page we've loaded:
        register_secondary_callbacks();
      });
    });
  });
}

function liked(elem){
  $.post('/entries/' + $(elem).attr("value") + "/liked", function(data) {
    $(elem).replaceWith("<b>liked</b>");
  });
  }

function disliked(elem){
  $.post('/entries/' + $(elem).attr("value") + "/disliked", function(data) {
      $(elem).replaceWith("<b>disliked</b>");
    });
}


function read(elem) {
  if(elem !== undefined) {
    $.post('/entries/' + $(elem).attr("value") + '/read', function(data) {
        $("#check" + $(elem).attr("value")).attr("checked", true);
      });
  }
}
