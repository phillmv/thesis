/* $('.entry').each(function() {
     var entry = $(this);

     var biggest = 0;

     if (entry.find("object").length != 0)
     {
      entry.addClass("col3");       
      return; 
     }

     entry.find('img').each(function() {
         if( biggest < $(this).width())
         {
           biggest = $(this).width();
         }
       });

     if(biggest > 460)
     {
       entry.addClass("col3");
       return;
     }

     if(biggest > 220)
     {
       entry.addClass("col2");
       return;
     }
      
     entry.addClass("col1");

   });*/
/* $('#content').masonry({
     columnWidth: 220
   });*/

function Magazine() {
  var controller = "/more";
  var entries = new Array();
  var entry_pos = -1;


  $(document).ready(function() {

      $(window).infinitescroll({
          url: function(){ return controller; },
          appendTo: '#content',
          triggerAt: 600
        });


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
        //read(entries[entry_pos]);
        dir = 1;
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
