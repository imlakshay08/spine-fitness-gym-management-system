  $(document).ready(function(){
    flatpickr("#ia_date", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });

    $(document).on("keypress","#issue_amount",function(e){

    var keycode = (e.keyCode ? e.keyCode : e.which );

      if( keycode == '13' ){

        filter_issue_amount();

      }

  

  });

  function filter_issue_amount(){

      var useroot = $("#rootXPath").val();

     

      $(".show_loader").removeClass("hidden");

      $(".no_loader").removeClass("hidden").addClass("hidden")

      $("form#myForms").submit(); 

  

  }