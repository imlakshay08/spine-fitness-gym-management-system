$(document).on("keypress","#user_search",function(e){
    var keycode = (e.keyCode ? e.keyCode : e.which );
      if( keycode == '13' ){
        filter_user_log();
      }
  
  });
function filter_user_log(){
    var useroot = $("#rootXPath").val();
      var from_date    = $.trim($("#search_fromdated").val());
  var upto_date  = $.trim($("#search_uptodated").val());
    //alert(useroot)
 if(from_date == ''){
    showToast("info","Please select From Date");
    return false;
  }
  if(upto_date == ''){
    showToast("info","Please select Upto Date");
    return false;
  }
    $("form#myforms").attr("action",useroot+"log_audit/search");
    $("form#myforms").submit();
}
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


$(document).ready(function(){

  flatpickr("#search_fromdated", {

    dateFormat: "d-M-Y",

    allowInput: true,

    onOpen: function (selectedDates, dateStr, instance) {

      instance.setDate(instance.input.value, false);

    },

  });

});

$(document).ready(function(){

  flatpickr("#search_uptodated", {

    dateFormat: "d-M-Y",

    allowInput: true,

    onOpen: function (selectedDates, dateStr, instance) {

      instance.setDate(instance.input.value, false);

    },

  });

});
