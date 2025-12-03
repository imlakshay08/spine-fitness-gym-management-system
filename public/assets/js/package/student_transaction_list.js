$(document).ready(function(){
    flatpickr("#trn_date", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });
  $(document).on("keypress","#rollno_search",function(e){
    var keycode = (e.keyCode ? e.keyCode : e.which );
      if( keycode == '13' ){
        filter_transaction();
      }
  
  });
function filter_transaction(){
    var useroot = $("#rootXPath").val();
    $(".show_loader").removeClass("hidden");
    $(".no_loader").removeClass("hidden").addClass("hidden")
    $("form#myForms").attr("action",useroot+"student_transaction_list/search");
    $("form#myForms").submit();
}

  $(document).on("keypress","#trn_stdnt_rollno",function(e){
    var keycode = (e.keyCode ? e.keyCode : e.which );
    // var prdcode = $("#trn_stdnt_rollno").val();
      if( keycode == '13' ){
        search_filter_student();
        setTimeout(function(){ fill_from_student();},500);
        setTimeout(function(){ search_general_details_student();},500);
        event.preventDefault();
      return false;
      }
  
  });
  $(document).on("keypress","#trn_stdnt_name",function(e){
    var keycode = (e.keyCode ? e.keyCode : e.which );
    var prdcode = $("#trn_stdnt_name").val();
      if( keycode == '13' ){
        search_name_student();
        // setTimeout(function(){ show_student_list(prdcode);},500);
        event.preventDefault();
      return false;
      }
  
  });

  function updateSemesterAndShowCard(semester) {
    var semesterText = semester === '2024' ? '1' : semester;
    $("#semester").text(semesterText + " Semester");
    $("#student-details-card").show();
}

  function search_general_details_student(){
    var usePath    = $.trim( $("#rootXPath").val() );
    var trn_stdnt_rollno    = $.trim( $("#trn_stdnt_rollno").val() );
    var stdnt_gn_code    = $.trim( $("#stdnt_gn_code").val() );
       if( trn_stdnt_rollno!='' ){ 
            $(".load_employee").removeClass("hidden");
            setTimeout(function(){
            $.ajax({
                        url: usePath+"student_transaction_list/ajax_process",
                        type: 'POST',
                        data: {'trn_stdnt_rollno': trn_stdnt_rollno,'stdnt_gn_code':stdnt_gn_code,'requestname': '','requesttype':'CODE','identity':'STUDENTGENDTL'},
                        async: false,
                        success: function (resp) {
                            $(".load_employee").removeClass("hidden").addClass("hidden");
                            if( resp.status){
                              

                                var sdata = resp.data;                    
                                $("#trn_cur_status").val(sdata.employeename);
                                updateSemesterAndShowCard(sdata.semester); // Call the new function
                                $("#trn_stdnt_rollno").val(sdata.employeecode);
                                $("#stdnt_gn_code").val(sdata.employeecode);
                             
                            }else{
                                $("#stdnt_gn_code").val('');
                                $("#semester").val('');
                                $("#trn_stdnt_rollno").val('');
                                $("#trn_prev_status").val('');
                                $("#trn_cur_status").val('');
                                alert("No record(s) found.");
                            }
                        
                        },
                        error: function () {
                            $("#stdnt_gn_code").val('');
                            $("#semester").val('');
                            $("#search_empcode").val('');
                            $("#trn_prev_status").val('');
                            $("#trn_cur_status").val('');
                            $(".load_employee").removeClass("hidden").addClass("hidden");
                        },
                        cache: false
            });

        },500);

        }
}

  function search_filter_student(){
    var usePath    = $.trim( $("#rootXPath").val() );
    var trn_stdnt_rollno    = $.trim( $("#trn_stdnt_rollno").val() );
    var stdnt_code    = $.trim( $("#stdnt_code").val() );
       if( trn_stdnt_rollno!='' ){ 
            $(".load_employee").removeClass("hidden");
            setTimeout(function(){
            $.ajax({
                        url: usePath+"student_transaction_list/ajax_process",
                        type: 'POST',
                        data: {'trn_stdnt_rollno': trn_stdnt_rollno,'stdnt_code':stdnt_code,'requestname': '','requesttype':'CODE','identity':'STUDENTDTLS'},
                        async: false,
                        success: function (resp) {
                            $(".load_employee").removeClass("hidden").addClass("hidden");
                            if( resp.status){
                                var sdata = resp.data;                    
                                $("#trn_stdnt_name").val(sdata.employeename);
                                $("#trn_stdnt_rollno").val(sdata.employeecode);
                                $("#stdnt_code").val(sdata.employeecode);
                             
                            }else{
                                $("#stdnt_code").val('');
                                $("#trn_stdnt_rollno").val('');
                                $("#trn_stdnt_name").val('');
                                alert("No record(s) found.");
                            }
                        
                        },
                        error: function () {
                            $("#stdnt_code").val('');
                            $("#search_empcode").val('');
                            $("#trn_stdnt_name").val('');
                            $(".load_employee").removeClass("hidden").addClass("hidden");
                        },
                        cache: false
            });

        },500);

        }
}

function search_name_student(){
    var usePath      = $.trim( $("#rootXPath").val() );
    var trn_stdnt_name  = $.trim( $("#trn_stdnt_name").val() );
    var trn_stdnt_rollno      = $.trim( $("#trn_stdnt_rollno").val() );
       if( trn_stdnt_name!='' ){ 
        $(".load_employee").removeClass("hidden");
        setTimeout(function(){
            $.ajax({
                        url: usePath+"student_transaction_list/ajax_process",
                        type: 'POST',
                        data: {'requestcode': '','trn_stdnt_rollno':trn_stdnt_rollno,'trn_stdnt_name': trn_stdnt_name,'requesttype':'','identity':'STUDENTDTLS'},
                        async: false,
                        success: function (resp) {
                            var nhtml = ''
                            $(".load_employee").removeClass("hidden").addClass("hidden");
                            if( resp.status){
                                 nhtml += '<select id="new_employee_select" onchange="selected_my_student_list(this.value);"><option value="">-Select-</option>'
                                var sdata = resp.data;                    
                                if(sdata.length >0 ){
                                   $(sdata).each(function(key,leds){
                                    nhtml += '<option value="'+leds.employeecode+','+leds.employeename+'">'+leds.employeename+'</option>';
                                   });     
                                }
                                nhtml += '</select>';
                            }else{
                                $("#stdnt_code").val('');
                                $("#trn_stdnt_rollno").val('');
                                $("#trn_stdnt_name").val('');
                                alert("No record(s) found.");
                            }
                            $("#stdnt_name").html(nhtml);
                        
                        },
                        error: function () {
                            $("#stdnt_name").html('');
                            $(".load_employee").removeClass("hidden").addClass("hidden");
                        },
                        cache: false
            });

        },500);

        }


}
function selected_my_student_list(val){            
    var nstr         = val.split(",");
    for(var i = 0; i < nstr.length; i++) {
       nstr[i] = nstr[i].replace(/'/g, "");
    }   
     if( nstr[0] =='null' ){
         nstr[0] = '';
     }
     if( nstr[1] =='null' ){
         nstr[1] = '';
     }
     $("#trn_stdnt_name").val(nstr[1]);
     $("#trn_stdnt_rollno").val(nstr[0]);
     $("#stdnt_code").val(nstr[0]);
     $("#stdnt_name").html('');
}

function fill_from_student() {
  var usePath = $.trim($("#rootXPath").val());
  var course = $.trim($("#trn_stdnt_name").val());
  var studentcode=$.trim($("#trn_stdnt_rollno").val());
  $("#student-details-card").hide();
  // clearStudentTable();

  if (course === "") {
      // Do nothing if no subject is selected
      return;
  }
  $.ajax({
      url: usePath + "student_transaction_list/ajax_process",
      type: 'POST',
      data: {'studentcode': studentcode, 'requesttype': 'CODE', 'identity': 'STUDENT'},
      async: false,
      success: function (resp) {
          if (resp.status) {
              var sdata = resp.data;
              var course = resp.course;
              var coursename = course.crse_descp; 
              
              $("#course_text").text(coursename);
              // updateSemesterAndShowCard(sdata.semester); // Call the new function
              // $("#typ").text(sdata.typ);
              $("#student-details-card").show();
            //   if (sdata.typ === "Theory" || sdata.typ === "Practical") {
            //     fill_group_dropdown(sdata.typ);
            // }
          } else {
              // Clear values if no record found
              $("#course_text").text('');
              // $("#semester").text('');
              // $("#typ").text('');
              
              alert("No record(s) found.");
          }
      },
      error: function () {
          // Clear values on error
          $("#course_text").text('');
          // $("#semester").text('');
          // $("#typ").text('');
      },
      cache: false
  });
}

$(document).ready(function() {
  var studentcode = $.trim($("#trn_stdnt_rollno").val());
  if (studentcode !== "") {
      fill_from_student();
      // $("#student-details-card").show();
  
    }
});
function alertChecked(url){
  if( confirm("Are you sure want to cancel ?")){
      window.location = url
  }
}