function Magazine() {
  var controller = "/more";
  var entries = new Array();
  var entry_pos = -1;
  var scroll_mutex = false;

  $(document).ready(function() {

      $("#content").infinitescroll({
          navSelector : "#navigation",
          nextSelector : "#navigation .next_page",
          itemSelector: "#content .entry"
        }, function() { scroll_mutex = false; });

      // I'm forcing j/k for navigation 'cos I can't be arsed to implement
      // greader-style selection-with-scrolling (it's prolly easier than
      // it looks, but I'm lazy and would rather add more basic features 
      // first). Ergo, when you scrollTo the last loaded item, it is often
      // too long and too far from the page boundary to automatically 
      // trigger the infinite scroll. By tying page loading to j/k scrolling
      // we should be able to avoid this.

      $(window).unbind('.infscr');

      enable_keybindings(); 
      register_callbacks();
      load_entries();
      select(1);

    });

  function enable_keybindings()
  {
    $(window).keydown(function(event){
        switch (event.keyCode) {
        case 74: // j
          scroll(true);
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
  }

  function register_callbacks()
  {
    $(".signal").click(function(e) {
        liked($(this).val(), $(this));
      });

    $(".noise").click(function(e) {
        disliked($(this).val(), $(this));
      });

    $(".delicious").click(function(e) {
      e.preventDefault();
    });

  }

  function scroll(direction) {
    if(entries[entry_pos + direction] != undefined)  
    {
      if (direction) {
        read(entries[entry_pos]);
        dir = 1;
        if((entries.size() < entry_pos + 5) && !scroll_mutex )
        {
          scroll_mutex = true;
          //alert("size:" + entries.size() + " pos: " + (entry_pos + 3));
          $(document).trigger('retrieve.infscr');
          load_entries();          
        }

      }
      else {
        dir = -1;
      }

      select(dir);
      $.scrollTo(entries[entry_pos], 300);
    }
  }

  function select(dir)
  {
    $(entries[entry_pos]).addClass("previously_selected");
    $(entries[entry_pos]).removeClass("selected");
    entry_pos = entry_pos + dir;

    $(entries[entry_pos]).removeClass("previously_selected");
    $(entries[entry_pos]).removeClass("unselected");    
    $(entries[entry_pos]).addClass("selected");
  }

  function load_entries()
  {
    // INEFFICIENT ZOMG
    // but from my experience perf hit is negligible.
    entries = $(".entry").map(function() { 
        return "#" + $(this).attr("id")
      }); 
  }

  function liked(value, button)
  {
    $.post('/entries/' + value + "/liked", function(data) {
        button.replaceWith("<b>liked</b>");
      });
  }

  function disliked(value, button)
  {
    $.post('/entries/' + value + "/disliked", function(data) {
        button.replaceWith("<b>disliked</b>");
      });
  }


  function read(elem) 
  {
    if(elem !== undefined) 
    {
      $.post('/entries/' + $(elem).attr("value") + '/read', function(data) {
          $("#check" + $(elem).attr("value")).attr("checked", true);
        });
    }
  }
}

mag = new Magazine();

$(function(){
    $('#subscriptions').masonry({ 
        columnWidth: 190
      });
  });


/*function enable_transition(kontroller, selector, endless, id)
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
*/
