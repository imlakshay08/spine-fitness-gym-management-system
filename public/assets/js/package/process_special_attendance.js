function processSpecialAttendance() {
  var usePath       = $.trim( $("#rootXPath").val() );
  var month   = $.trim($("#psa_month").val());
  var year       = $.trim($("#psa_year").val());

  if(!month){
    showToast("info","Please select month.");
    return false;
  }

   if(!year){
    showToast("info","Please select year.");
    return false;
  }
 
        $("#show_loader").removeClass("hidden");
        $("#no_loader").removeClass("hidden").addClass("hidden");
   $.ajax({

               url: usePath+"process_special_attendance/ajax_process",
               type: 'POST',
               data: {identity: 'SPECIAL',
                      psa_month: month,
                      psa_year: year},
               async: false,
               success: function (resp) {
                    $("#show_loader").removeClass("hidden").addClass("hidden");
                    $("#no_loader").removeClass("hidden");
                    if(resp.status){
                        alert(resp.message);
                    }else{
                        alert("No record(s) found.");
                        return false;
                    }
               },
               error: function () {
                    $("#show_loader").removeClass("hidden").addClass("hidden");
                    $("#no_loader").removeClass("hidden");
               },
               cache: false
       });
}
