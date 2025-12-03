function genrate_year_end_process(){
  var usePath = $("#rootXPath").val();
  var endprocess_year = $("#yep_year").val();

  if (!endprocess_year) {
      alert("Please select a year.");
      return;
  }

  $("#no_loader").addClass("hidden");
  $(".show_loader").removeClass("hidden");

  $.ajax({
      url: usePath + "year_end_process/ajax_process",
      type: 'POST',
      data: { "endprocess_year": endprocess_year, "identity": "YEARENDPROCESS" },
      success: function(resp) {
          alert(resp.message);  
          $("#no_loader").removeClass("hidden");
          $(".show_loader").addClass("hidden");
      },
      error: function(xhr, status, error) {
          showToast('error', "An error occurred: " + error);
          $("#no_loader").removeClass("hidden");
          $(".show_loader").addClass("hidden");
      }
  });
}
