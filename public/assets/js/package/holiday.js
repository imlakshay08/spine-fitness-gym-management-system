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
        window.location = url
    }
  }