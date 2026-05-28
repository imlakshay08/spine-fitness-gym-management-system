

  function applyFilter() {
      var useroot = $("#rootXPath").val();
      $("#payments-table-loader").addClass("active");
      $(".show_loader_pay").removeClass("hidden");
      $(".no_loader_pay").addClass("hidden");
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
