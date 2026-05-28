

  function applyFilter() {
      var useroot = $("#rootXPath").val();
      $('#paymentFilterForm').attr("action",useroot+"trn_payments/search");
      $('#paymentFilterForm').submit();
  }
  
$(document).ready(function(){
    flatpickr("#payments_from_date", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });

  $(document).ready(function(){
    flatpickr("#payments_to_date", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });
