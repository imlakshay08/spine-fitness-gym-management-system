function search_filter(){

    var useroot = $("#rootXPath").val();
  
    $(".show_loader").removeClass("hidden");
  
    $(".no_loader").removeClass("hidden").addClass("hidden")
  
    $("form#myForms").attr("action",useroot+"inventory_outlet/search");
  
    $("form#myForms").submit();
  
  }

  
function inventory_outlet_download_excel(){
    var usePath      = $.trim( $("#rootXPath").val() );
    var printexcelpath = $.trim( $("#productexeclurl").attr("rel") );
    var from_date = $.trim( $("#from_date").val() );
    var upto_date = $.trim( $("#upto_date").val() );
    var outlet  = $.trim( $("#my_outletname").val() );
    var chekexcel    = ""
    if( $("input[name='inventoryoutlet']").is(":checked")){
        chekexcel = $("input[name='inventoryoutlet']:checked").val();
    }
     $.ajax({
              url: usePath+"inventory_outlet/ajax_process",
              type: 'POST',
              data: {'identity':'Y','asondated':from_date,'uptodated':upto_date,'my_outletname':outlet,'report_type':chekexcel},
              async: false,
              success: function (resp) {
                       if( resp.status){

                          window.open(printexcelpath, '_blank');
                     }else{
                      alert("No record(s) found.");
                    }
              },
              error: function () {
              },  
              cache: false

     });
  
  }
