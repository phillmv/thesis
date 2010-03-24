// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var controller = "/more";
var entries = new Array();
var entry_pos = -1;

$(document).ready(function() {

  $(window).infinitescroll({
      url: function(){ return controller; },
      appendTo: '#content',
      triggerAt: 600
  });

  $(window).keydown(function(event){
    switch (event.keyCode) {
      case 74: // j
        scroll(true);
        load_entries();        
        break;

      case 75: // k
        scroll(false);
        break;
      
      // TODO: refactor around unobtrusive js, so this is less clumsy
      // this is pretty ugly right now. but it works!
      case 85:
        if (entries[entry_pos] !== undefined) {
          val = $(entries[entry_pos]).attr("value");
          liked(val, $("#signal" + val));
        }
        break;

      case 78:
        if (entries[entry_pos] !== undefined) {
          val = $(entries[entry_pos]).attr("value");
          disliked(val, $("#noise" + val));
        }
        break;
      }
  });


    signal_and_noise();

    enable_transition("/subscriptions/", "#subscriptions", false);
    enable_transition("/classifications/", "#classifications");
    enable_transition("/", "#home");

  });


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
  signal_and_noise();
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

function signal_and_noise()
{
  $(".signal").click(function(e) {
      liked($(this).val(), $(this));
    });

  $(".noise").click(function(e) {
      disliked($(this).val(), $(this));
    });

}

function liked(value, button){
  $.post('/entries/' + value + "/liked", function(data) {
    button.replaceWith("<b>liked</b>");
  });
  }

function disliked(value, button){
  $.post('/entries/' + value + "/disliked", function(data) {
      button.replaceWith("<b>disliked</b>");
    });
}


function read(elem) {
  if(elem !== undefined) {
    $.post('/entries/' + $(elem).attr("value") + '/read', function(data) {
        $("#check" + $(elem).attr("value")).attr("checked", true);
      });
  }
}
