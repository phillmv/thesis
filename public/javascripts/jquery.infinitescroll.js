// Infinite Scroll via http://github.com/brianmario/jquery-infinite-scroll
(function($) {
  $.fn.infinitescroll = function(options) {
    return $(this).each(function() {
      var el = $(this);
      var settings = $.extend({
        url: null,
        triggerAt: 300,
        page: 2,
        appendTo: '.list tbody',
        container: $(document)
      }, options);
      var req = null;
      var maxReached = false;
      var last_url = settings.url();

      var infinityRunner = function() {
        // So, I have different pages on which I want endless pageless to
        // work on. They both have large sets of entries to scroll through.
        // Normally this isn't a problem; just set up a function that 
        // initializes this plugin with the different url.
        //
        // However, I don't want any page reloads. I think this is a semi
        // reasonable/fashionable request to make. So, either I grossly
        // misunderstand the nature of how JQuery plugins work (v. likely)
        // or it's simply not possible to reinitialize this function.
        //
        // So, I tweaked settings.url to expect a function instead of a
        // string. Furthermore, when the url changes, we should reinit
        // the page count so that the request goes through properly.
        var url = settings.url();
        if (url !== null) {
          if(last_url !== url)
          {
            last_url = url;
            settings.page = 2;
          }

          if  (settings.force || (settings.triggerAt >= (settings.container.height() - el.height() - el.scrollTop()))) {
            settings.force = false;
            // if the request is in progress, exit and wait for it to finish
            if (req && req.readyState < 4 && req.readyState > 0) {
              return;
            }
            $(settings.appendTo).trigger('infinitescroll.beforesend');
            
            req = $.get(settings.url(), 'page='+settings.page, function(data) {
              if (data !== '') {
                if (settings.page > 1) {
                  $(settings.appendTo).append(data);
                } else {
                  $(settings.appendTo).html(data);
                }
                settings.page++;
                $(settings.appendTo).trigger('infinitescroll.finish');
              } else {
                maxReached = true;
                $(settings.appendTo).trigger('infinitescroll.maxreached');
              }
            }, 'html');
          }
        }
      };

      el.bind('infinitescroll.scrollpage', function(e, page) {
        alert(el.height());
        settings.page = page;
        settings.force = true;
        infinityRunner();
      });

      el.scroll(function(e) {
        if (!maxReached) {
          infinityRunner();
        }
      });

      // Test initial page layout for trigger
      infinityRunner();
    });
  };
})(jQuery);
