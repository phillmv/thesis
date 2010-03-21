// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var controller = "/more";

$(document).ready(function() {

  $(window).infinitescroll({
    url: function(){ return controller; },
    appendTo: '#content'
  });


  enable_transition("/subscriptions/", "#subscriptions", false);
  enable_transition("/classifications/", "#classifications");
  enable_transition("/", "#home");
  
});

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
  $.post('/entries/' + $(elem).val() + "/liked", function(data) {
    $(elem).replaceWith("<b>liked</b>");
  });
  }

function disliked(elem){
  $.post('/entries/' + $(elem).val() + "/disliked", function(data) {
      $(elem).replaceWith("<b>disliked</b>");
    });
}


function read(elem) {
  $.post('/entries/' + $(elem).val() + '/read', function(data) {
  });
}
