// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function() {
  //  alert("start");

  if ($("#content").length != 0) {
    $(window).infinitescroll({
      url: window.location.href + "more",
      appendTo: '#content'
    });
  }

});

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
