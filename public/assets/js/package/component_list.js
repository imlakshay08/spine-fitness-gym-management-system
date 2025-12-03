function alertChecked(url){
    if( confirm("Are you sure want to delete ?")){
        window.location = url
    }
  }
  function isNumberMyKeys(evt) {
    evt = (evt) ? evt : window.event;
    var charCode = (evt.which) ? evt.which : evt.keyCode;
    if (charCode > 31 && (charCode < 48 || charCode > 57)) {
        return false;
    }
    return true;
  }
  $(document).on("keypress","#component_list",function(e){
    var keycode = (e.keyCode ? e.keyCode : e.which );
      if( keycode == '13' ){
        filter_component_list();
      }
  
  });
  function filter_component_list(){
      var useroot = $("#rootXPath").val();
     
      $(".show_loader").removeClass("hidden");
      $(".no_loader").removeClass("hidden").addClass("hidden")
      $("form#myForms").submit(); 
  
  }