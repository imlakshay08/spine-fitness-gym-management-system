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