/*
---
title: Toggle
name: toggle
category: Javascript
---

Toggles should be used display show/hide comment. For example, showing/hiding a additional information on the search results page.
You can set the default as either active or inactive by specifying the class on the span to be either `toggleActive` or `toggleInactive`,
and setting (or not setting) the class `hideVisually` on the container that you are toggling.

Here's how you kick this off:

```html_example
<a href="#toggleArrow1" class="toggle toggleArrow " data-toggle-text="Fewer Options">More Options</a>
<div id="toggleArrow1" class="hideVisually">Yo, I got some content to show you. Lorem ipsum occaecat eiusmod Ut et sit sint quis qui labore in exercitation
  esse. Lorem ipsum in aliquip esse anim aliquip ullamco sit dolor in deserunt eu labore. Lorem ipsum magna
  officia in laborum fugiat proident cupidatat in ex aliquip velit officia nulla aliquip ut. Lorem ipsum
  nostrud ad Ut nulla velit qui esse tempor Excepteur consectetur pariatur enim.
</div>
```

```js_example
$(document).ready(function () {
  $('.toggle').truliaToggle();
});
```

Below are some methods you can also call on the toggle component and events you can listen to:

method          | description
----------------|------------------------
`toggle`        | Toggle the tooltip. Optional boolean argument to force active. Example: `$('.toggle').truliaToggle('toggle', true)`
**events**      |
`toggle`        | Listen to this event to perform an action when the toggle has changed state `$('.toggle').on('toggle', function (e, active) { if (active) console.log('I\m Active!') })`

*/

;(function ($) {
  var setArrow = function($el) {
    if ($el.hasClass('toggleArrow'))
    {
      $el.toggleClass('toggleArrowActive');
    }
  };

  var methods = {
    init: function () {
      return this.each(function () {
        if ($(this).data('toggleInit') !== true) {
          //Prevent multiple initializations
          $(this).data('toggleInit', true);

          $(this).click(function (event) {
            event.preventDefault();
            methods.toggle.apply(this);
          });
        }
      });
    },

    toggle: function (activate) {
      return $(this).each(function () {
        var $toggle,
            data,
            container,
            toggled = false;

        $toggle = $(this);

        container = $($toggle.attr('href'));

        if (activate || activate === false)
        {
          // forced state toggle
          toggled = container.hasClass('hideVisually') === activate;
          $toggle.toggleClass('toggleActive', activate);
          container.toggleClass('hideVisually', !activate);
        }
        else
        {
          // toggle
          toggled = true;
          $toggle.toggleClass('toggleActive');
          container.toggleClass('hideVisually');
        }

        if (toggled)
        {
          // update arrow status
          setArrow($toggle);

          // update the label
          data = $toggle.data();
          if (data.toggleText) {
            var show = data.toggleText;

            //store our current text
            $toggle.data('toggleText', $toggle.text());

            //switch to our toggle text
            $toggle.text(show);
          }

          $toggle.trigger('toggle', [(activate || $toggle.hasClass('toggleActive'))]);
        }
      });
    }

  };

  $.fn.truliaToggle = function (method) {
    if (typeof method === 'string' && typeof methods[method] === 'function')
    {
      return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    }
    else if (typeof method === 'object' || !method)
    {
      return methods.init.apply(this, arguments);
    }
    else
    {
      $.error('Method ' +  method + ' does not exist on jQuery.truliaToggle');
    }
  };

}(jQuery));
