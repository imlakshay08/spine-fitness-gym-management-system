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
        window.location = url
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
