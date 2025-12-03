function validate_cs_file(){
    var checkfile   = "";
    var checkupdate = ""
    var file        = $.trim( $("#file").val() );    
    var emp_location = $.trim( $("#emp_location").val() );
    if( $("input[name='data_imports']").is(":checked") ){
        checkfile = $("input[name='data_imports']:checked").val();
    }
    if( $("input[name='checkscale_updated']").is(":checked") ){
        checkupdate = $("input[name='checkscale_updated']:checked").val();
    }
    if( file == ''){
        alert("Please select a file for import.");
        return false;
    }
    if( checkfile == 'employee' || checkfile =='attendance'){
        if( document.getElementById("file").value.toLowerCase().lastIndexOf(".csv")==-1) 
        {   
            alert("Selected file should be in CSV.")
            return false;
        }
    }
    if( checkfile == 'atdrawfile' || checkfile =='attendance' ){
           if( emp_location == ''){
            alert("Location is required.")
            return false;
         }
    }
    if( checkupdate == 'Y'){
        if( confirm("Do you want to update scale?")){
           // check status
        }else{
            return false;
        }
    }

}

function get_fee_import_process(){
    var usePath = $.trim($("#rootXPath").val());
    var formData = new FormData();
    var file        = $('#file').get(0).files[0];  
    
    formData.append("identity", "FEEIMPORT");
    formData.append("file", file);
    $.ajax({
        url: usePath + "fee_import/ajax_process",
        type: 'POST',
        data: formData,
        processData: false,
        contentType: false,
        success: function(resp) {
          if (resp.status) {
            //clear_fee_fields();
            $("#fee_import").html(resp.data);
  
          } else {
            //showToaster( resp.message);
            $("#fee_import").html('<tr><td colspan="4">No record(s) found.</td></tr>');
  
          }
        },
        error: function(xhr, status, error) {
          showToast('error', "An error occurred :" + error);
  
          
        }
      });
}