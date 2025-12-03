function common_process(){
  $("#no_loader").addClass("hidden");
  $(".show_loader").removeClass("hidden");
  setTimeout(function(){ genrate_fee_process(); },500);
}

function genrate_fee_process(){
  var usePath = $("#rootXPath").val();
  var feepr_year = $("#feepr_year").val();

  if (!feepr_year) {
      alert("Please select a year.");
      return;
  }

  $.ajax({
      url: usePath + "fee_process/ajax_process",
      type: 'POST',
      data: { "feepr_year": feepr_year, "identity": "FEEPROCESS" },
      async: false,
      success: function(resp) {
          if (resp.status) {
         // Show button, hide loader
              alert(resp.message);
          } else {
          // Show button, hide loader
              alert(resp.message);
          }
          $("#no_loader").removeClass("hidden");
          $(".show_loader").addClass("hidden");
      },
      error: function(xhr, status, error) {
          showToast('error', "An error occurred: " + error);
          $("#no_loader").show();
          $(".show_loader").hide();
      }
  });
  $("#no_loader").removeClass("hidden");
  $(".show_loader").addClass("hidden");
}
