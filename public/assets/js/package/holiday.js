$(document).ready(function(){

    flatpickr("#holiday_date", {
  
      dateFormat: "d-M-Y",
  
      allowInput: true,
  
      onOpen: function (selectedDates, dateStr, instance) {
  
        instance.setDate(instance.input.value, false);
  
      },
  
    });
  
  });
  function alertChecked(url){
      if( confirm("Are you sure want to delete ?")){
          // Submitted as DELETE via a real form rather than window.location.
          // A delete used to be a plain GET, which meant a link prefetcher, a
          // "preload pages" browser setting, or anything that fetches a URL on
          // the admin's behalf could destroy a record without a click.
          var form = document.createElement("form");
          form.method = "post";
          form.action = url;
          form.style.display = "none";

          var m = document.createElement("input");
          m.type = "hidden"; m.name = "_method"; m.value = "delete";
          form.appendChild(m);

          var meta = document.querySelector('meta[name="csrf-token"]');
          if (meta) {
              var t = document.createElement("input");
              t.type = "hidden"; t.name = "authenticity_token"; t.value = meta.getAttribute("content");
              form.appendChild(t);
          }

          document.body.appendChild(form);
          form.submit();
      }
  }