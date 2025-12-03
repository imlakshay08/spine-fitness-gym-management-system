

function print_faculty_id(){
    var usePath           = $.trim( $("#userXRoot").val() );
    var faculty_code      = $.trim( $("#faculty_code").val() );
    var faculty_code_upto = $.trim( $("#faculty_code_upto").val() );
    var printurl          = $.trim( $("#printexceled").attr("rel") );
    var chekexcel         = ""
    if( $("input[name='id_detail']").is(":checked")){
        chekexcel = $("input[name='id_detail']:checked").val();
    }
    if(faculty_code === "" || faculty_code_upto === ""){
        alert("Please select both 'From' and 'Upto' to proceed.");
        return false;
}
     $.ajax({
                 url: usePath+"faculty_id_card/ajax_process",
                 type: 'POST',
                 data: {'faculty_code':faculty_code,'faculty_code_upto':faculty_code_upto,'sltype':chekexcel,'identity':'Y'},
                 async: false,
                 success: function (resp) {
                      if(resp.status){
                          window.open(usePath+printurl, '_blank');
                      }else{
                          alert("No record(s) found.");
                          return false;
                      }
                 },
                 error: function () {

                 },
                 cache: false
         });


}