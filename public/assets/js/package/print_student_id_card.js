

function print_student_id(){
    var usePath      = $.trim( $("#userXRoot").val() );
    var course_code    = $.trim( $("#course_code").val() );
    var stdnt_roll_no  = $.trim( $("#stdnt_roll_no").val() );
    var roll_no_upto   = $.trim( $("#roll_no_upto").val() );
    var printurl       = $.trim( $("#printexceled").attr("rel") );
    var chekexcel    = ""
    if( $("input[name='id_detail']").is(":checked")){
        chekexcel = $("input[name='id_detail']:checked").val();
    }
    if(stdnt_roll_no === "" || roll_no_upto === ""){
        alert("Please select both 'From' and 'Upto' to proceed.");
        return false;
}
     $.ajax({
                 url: usePath+"print_student_id_card/ajax_process",
                 type: 'POST',
                 data: {'course_code':course_code,'stdnt_roll_no':stdnt_roll_no,'roll_no_upto':roll_no_upto,'sltype':chekexcel,'identity':'Y'},
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