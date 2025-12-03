function get_global_attendance(){

  // setTimeout(function(){ show_student_list(); },500);

  setTimeout(function(){ save_student_detail(); },500);

}



function updateSemesters() {

  var usePath           = $.trim($("#rootXPath").val());

  var course_code       = $.trim($("#sp_att_crse").val());

  var selectedSemester  = $("#sp_att_sem").data("selected-semester"); // Get the preselected semester



  $.ajax({

      url: usePath + 'subject_list/ajax_process',

      type: 'POST',

      data: { "course_code": course_code, identity: 'SEMESTER' },

      async: false,

      success: function (resp) {

          var vhtml = '<option value="">-Select-</option>';

          if (resp.status) {

              var sdata = resp.data;

              $.each(sdata, function (index, semester) {

                  var selected = (semester == selectedSemester) ? 'selected' : '';

                  vhtml += '<option value="' + semester + '" ' + selected + '>Semester ' + semester + '</option>';



              });

          }

          $("#sp_att_sem").html(vhtml);

      },

      error: function () {

          console.error('Error fetching semesters');

      },

      cache: false

  });

}



$(document).on("keypress","#sp_att_std_rollno",function(e){

    var keycode = (e.keyCode ? e.keyCode : e.which );

    var prdcode = $("#sp_att_std_rollno").val();

      if( keycode == '13' ){

        search_filter_student();

        // setTimeout(function(){ show_student_list(prdcode);},500);

        event.preventDefault();

      return false;

      }

  

  });

  $(document).on("keypress","#sp_att_std_name",function(e){

    var keycode = (e.keyCode ? e.keyCode : e.which );

    var prdcode = $("#sp_att_std_name").val();

      if( keycode == '13' ){

        search_name_student();

        // setTimeout(function(){ show_student_list(prdcode);},500);

        event.preventDefault();

      return false;

      }

  

  });

  function search_filter_student() {

    var usePath = $.trim($("#rootXPath").val());

    var sp_att_std_rollno = $.trim($("#sp_att_std_rollno").val());

    var stdnt_code = $.trim($("#stdnt_code").val());

    var sp_att_crse = $.trim($("#sp_att_crse").val());

    var sp_att_sem = $.trim($("#sp_att_sem").val());


    if (sp_att_std_rollno !== '') {

        $(".load_employee").removeClass("hidden");



        setTimeout(function () {

            $.ajax({

                url: usePath + "subject_list/ajax_process",

                type: 'POST',

                data: {

                    'sp_att_std_rollno': sp_att_std_rollno,

                    'sp_att_crse': sp_att_crse,

                    'sp_att_sem': sp_att_sem,

                    'stdnt_code': stdnt_code,

                    'requestname': '',

                    'requesttype': 'CODE',

                    'identity': 'STUDENTDTLS'

                },

                async: false,

                dataType: 'json',

                success: function (resp) {

                    $(".load_employee").addClass("hidden");

                    if (resp.status) {

                        var sdata = resp.data;

                        $("#sp_att_std_name").val(sdata.employeename);

                        $("#sp_att_std_rollno").val(sdata.employeecode);

                        $("#stdnt_code").val(sdata.employeecode);

                    } else {

                     

                        alert("No record(s) found.");

                    }

                },

                error: function () {

                    

                    $(".load_employee").addClass("hidden");

                },

                cache: false

            });

        }, 500);

    }

}



function search_name_student() {

    var usePath = $.trim($("#rootXPath").val());

    var sp_att_std_name = $.trim($("#sp_att_std_name").val());
    var sp_att_crse = $.trim($("#sp_att_crse").val());

    var sp_att_sem = $.trim($("#sp_att_sem").val());



    if (sp_att_std_name !== '') {

        $(".load_employee").removeClass("hidden");



        setTimeout(function () {

            $.ajax({

                url: usePath + "subject_list/ajax_process",

                type: 'POST',

                data: {

                    'requestcode': '',
                    'sp_att_std_name': sp_att_std_name,
                    'sp_att_crse': sp_att_crse,

                    'sp_att_sem': sp_att_sem,

                    'requesttype': '',

                    'identity': 'STUDENTDTLS'

                },

                async: false,

                success: function (resp) {

                    $(".load_employee").addClass("hidden");

                    var nhtml = '';



                    if (resp.status) {

                        nhtml += '<select id="new_employee_select" onchange="selected_my_student_list(this.value);"><option value="">-Select-</option>';

                        var sdata = resp.data;



                        if (sdata.length > 0) {

                            $.each(sdata, function (key, leds) {

                                nhtml += `<option value="${leds.employeecode},${leds.employeename}">${leds.employeename}</option>`;

                            });

                        }



                        nhtml += '</select>';

                    } else {

                        clearStudentInputs();

                        alert("No record(s) found.");

                    }



                    $("#stdnt_name").html(nhtml);

                },

                error: function () {

                    $("#stdnt_name").html('');

                    $(".load_employee").addClass("hidden");

                },

                cache: false

            });

        }, 500);

    }

}



function clearStudentInputs() {

    $("#stdnt_code").val('');

    $("#sp_att_std_rollno").val('');

    $("#sp_att_std_name").val('');

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

     $("#sp_att_std_name").val(nstr[1]);

     $("#sp_att_std_rollno").val(nstr[0]);

     $("#stdnt_code").val(nstr[0]);

     $("#stdnt_name").html('');

}


 $(document).ready(function(){
  flatpickr("#sp_att_date", {
    dateFormat: "d-M-Y",
    allowInput: false,       
    defaultDate: "today",  
    minDate: new Date().fp_incr(-60),        
    maxDate: "today",
    onOpen: function (selectedDates, dateStr, instance) {
      instance.setDate(instance.input.value, false);
    },
  });
 });


  

function clear_material_fields() {

  $("#sp_att_std_rollno").val('');

  $("#sp_att_std_name").val('');

  $("#prepid").val('');

  $("#currprodcode").val('');

  $("#sp_att_fclty").val('')

  $("#sp_att_date").val('');

  $("#sp_att_crse").val('') ;

  $("#sp_att_house").val('');

  $("#sp_att_prd").val('');

  $("#sp_att_sem").val('');

  $('#sp_att_actvty').val('');

  $("#sp_att_grp").val('');

  $("#sp_att_chckbx").val('');

  $('#specialAttendId').val('');

}



function clear_student_fields(){

  $("#sp_att_std_rollno").val('');

  $("#sp_att_std_name").val('');

  $("#prepid").val('');

  $("#currprodcode").val('');

}



function save_student_detail() {

  var usePath              = $.trim( $("#rootXPath").val() );

  var formData             = new FormData();

  var mid                  = $.trim( $("#specialAttendId").val() );



  var sp_att_date      = $.trim( $("#sp_att_date").val() );

  var sp_att_fclty      = $.trim( $("#sp_att_fclty").val() );

  var sp_att_crse      = $.trim( $("#sp_att_crse").val() );

  var sp_att_sem      = $.trim( $("#sp_att_sem").val() );

  var sp_att_house      = $.trim( $("#sp_att_house").val() );

  var sp_att_actvty      = $.trim( $("#sp_att_actvty").val() );

  var sp_att_prd      = $.trim( $("#sp_att_prd").val() );

  var sp_att_std_name      = $.trim( $("#sp_att_std_name").val() );

  var sp_att_std_rollno      = $.trim( $("#sp_att_std_rollno").val() );



  if( sp_att_fclty == ''){

    showToast("error","Faculty is required.");

    setTimeout(function(){ set_global_focus('sp_att_fclty');},500);

    return false;

  }else if( sp_att_date == ''){

    showToast("error","Date is required.");

    setTimeout(function(){ set_global_focus('sp_att_date');},500);

    return false;

  }else if( sp_att_crse == ''){

    showToast("error","Course is required.");

    setTimeout(function(){ set_global_focus('sp_att_crse');},500);

    return false;

  }

  else if( sp_att_sem == ''){

    showToast("error","Semester is required.");

    setTimeout(function(){ set_global_focus('sp_att_sem');},500);

    return false;

  }

  else if( sp_att_house == ''){

    showToast("error","House is required.");

    setTimeout(function(){ set_global_focus('sp_att_house');},500);

    return false;

  }

  else if( sp_att_actvty == ''){

    showToast("error","Activity is required.");

    setTimeout(function(){ set_global_focus('sp_att_actvty');},500);

    return false;

  }

  else if( sp_att_std_name == ''){

    showToast("error","Student Name is required.");

    setTimeout(function(){ set_global_focus('sp_att_std_name');},500);

    return false;

  }

  else if( sp_att_std_rollno == ''){

    showToast("error","Student Roll No. is required.");

    setTimeout(function(){ set_global_focus('sp_att_std_rollno');},500);

    return false;

  }

  formData.append("identity", "STUDNTATTNDNC");

  formData.append("sp_att_crse", sp_att_crse); 

  formData.append("sp_att_sem", sp_att_sem); 

  formData.append("sp_att_house", sp_att_house); 

  formData.append("sp_att_actvty", sp_att_actvty); 

  formData.append("sp_att_date", sp_att_date); 

  formData.append("specialAttendId", mid);

  formData.append("sp_att_fclty", sp_att_fclty); 

  formData.append("sp_att_std_name", sp_att_std_name); 

  formData.append("sp_att_std_rollno", sp_att_std_rollno); 





  $(".no_loader").removeClass("hidden").addClass("hidden");

  $(".loader").removeClass("hidden");    



  setTimeout(function(){

    $.ajax({

           url: usePath+"subject_list/ajax_process",

           type: 'POST',

           data: formData,

           async: false,

           contentType: false,

           processData: false,

           success: function (resp) {               

              if( resp.status ){         



                $("#view_special_attendance").html(resp.data);

                $(".no_loader").removeClass("hidden");

                $(".loader").removeClass("hidden").addClass("hidden"); 

                // showToast("success",resp.message); 

  

                setTimeout(function(){ clear_student_fields();},500);         

                       



              }else{

                  $(".no_loader").removeClass("hidden");

                  $(".loader").removeClass("hidden").addClass("hidden");     

                  $(".process_qualif_save").show();

                  alert(resp.message); 

                

              }

           },

           error: function () {

            $(".no_loader").removeClass("hidden");

            $(".loader").removeClass("hidden").addClass("hidden");     

           },

           cache: false

   });



  },500);

}

function delete_student_from_list(rollno, date, faculty, course, semester, activity) {

  var usePath = $.trim($("#rootXPath").val());



  if (confirm('Are you sure you want to remove this student from Attendance?')) {

    $.ajax({

      url: usePath + "subject_list/ajax_process",

      type: 'POST',

      dataType: 'json',

      data: {

        identity: 'DELETEFROMATTENDANCE',

        sp_att_std_rollno: rollno,

        sp_att_date: date,

        sp_att_fclty: faculty,

        sp_att_crse: course,

        sp_att_sem: semester,

        sp_att_actvty: activity

      },

      success: function(response) {

        if (response.status) {

          showToast('success', response.message);

          $('#student_' + rollno).closest('tr').remove();  // Remove the entire row

        } else {

          showToast('error', response.message);

        }

      },

      error: function(xhr, status, error) {

        showToast('error', 'An error occurred: ' + error);

      }

    });

  }

}





function isAttendanceMySubmit() {

  var usePath = $.trim($("#rootXPath").val());

  var formData = new FormData();

  var sp_att_date      = $.trim( $("#sp_att_date").val() );

  var sp_att_fclty      = $.trim( $("#sp_att_fclty").val() );

  var sp_att_crse      = $.trim( $("#sp_att_crse").val() );

  var sp_att_sem      = $.trim( $("#sp_att_sem").val() );

  var sp_att_house      = $.trim( $("#sp_att_house").val() );

  var sp_att_actvty      = $.trim( $("#sp_att_actvty").val() );  

  var student = $.trim($("#specialAttendId").val());

  var studentroll = $("input[name='student_rollno[]']").eq(student).val();

  formData.append("sp_att_crse", sp_att_crse); 

  formData.append("sp_att_sem", sp_att_sem); 

  formData.append("sp_att_house", sp_att_house); 

  formData.append("sp_att_actvty", sp_att_actvty); 

  formData.append("sp_att_date", sp_att_date); 



  $("input[name='student_rollno[]']").each(function () {

      formData.append("student_rollno[]", this.value);

    

  });

  // Collect all checkbox values

  $("input[name='sp_att_prd1[]']").each(function () {

    if (this.checked) {

      formData.append("sp_att_prd1[]", this.value);

    } else {

      formData.append("sp_att_prd1[]", "N");

    }

  });



  $("input[name='sp_att_prd2[]']").each(function () {

    if (this.checked) {

      formData.append("sp_att_prd2[]", this.value);

    } else {

      formData.append("sp_att_prd2[]", "N");

    }

  });



  $("input[name='sp_att_prd3[]']").each(function () {

    if (this.checked) {

      formData.append("sp_att_prd3[]", this.value);

    } else {

      formData.append("sp_att_prd3[]", "N");

    }

  });



  $("input[name='sp_att_prd4[]']").each(function () {

    if (this.checked) {

      formData.append("sp_att_prd4[]", this.value);

    } else {

      formData.append("sp_att_prd4[]", "N");

    }

  });



  $("input[name='sp_att_prd5[]']").each(function () {

    if (this.checked) {

      formData.append("sp_att_prd5[]", this.value);

    } else {

      formData.append("sp_att_prd5[]", "N");

    }

  });



  $("input[name='sp_att_prd6[]']").each(function () {

    if (this.checked) {

      formData.append("sp_att_prd6[]", this.value);

    } else {

      formData.append("sp_att_prd6[]", "N");

    }

  });



  $("input[name='sp_att_prd7[]']").each(function () {

    if (this.checked) {

      formData.append("sp_att_prd7[]", this.value);

    } else {

      formData.append("sp_att_prd7[]", "N");

    }

  });



  $("input[name='sp_att_prd8[]']").each(function () {

    if (this.checked) {

      formData.append("sp_att_prd8[]", this.value);

    } else {

      formData.append("sp_att_prd8[]", "N");

    }

  });

  formData.append("identity", "UPDTPRDS");

  $(".no_loader").removeClass("hidden").addClass("hidden");

  $(".loader").removeClass("hidden");

  formData.append("sp_att_fclty", sp_att_fclty); 



  $.ajax({

    url: usePath + "subject_list/ajax_process",

    type: "POST",

    data: formData,

    async: false,

    contentType: false,

    processData: false,

    success: function (resp) {

      if (resp.status) {

        $(".no_loader").removeClass("hidden");

        $(".loader").removeClass("hidden").addClass("hidden");

        alert(resp.message);

        $("#sp_att_std_rollno").val('');

        $("#sp_att_std_name").val('');

        $("#prepid").val('');

        $("#currprodcode").val('');

        $("#sp_att_fclty").val('')

        $("#sp_att_date").val('');

        $("#sp_att_crse").val('') ;

        $("#sp_att_house").val('');

        $("#sp_att_prd").val('');

        $("#sp_att_sem").val('');

        $('#sp_att_actvty').val('');

        $("#sp_att_grp").val('');

        $("#sp_att_chckbx").val('');

        $('#specialAttendId').val('');

        $("#view_special_attendance").html('');

        window.location = usePath+"special_attendance"

      } else {

        $(".no_loader").removeClass("hidden");

        $(".loader").removeClass("hidden").addClass("hidden");

        alert(resp.message);

      }

    },

    error: function () {

      $(".no_loader").removeClass("hidden");

      $(".loader").removeClass("hidden").addClass("hidden");

    },

    cache: false,

  });

}



function set_global_focus(id){

  $("#"+id).focus();

}



function empty_faculty_club(){

  // Reset the Faculty dropdown

  var facultyDropdown = document.getElementById("sp_att_fclty");

  if (facultyDropdown) {

      facultyDropdown.value = ""; // Reset to default option

  }



  // Reset the Club dropdown

  var clubDropdown = document.getElementById("sp_att_house");

  if (clubDropdown) {

      clubDropdown.value = ""; // Reset to default option

  }

 }



 function reset_all_fields(){

  var CourseDropdown = document.getElementById("sp_att_crse");

  if (CourseDropdown) {

    CourseDropdown.value = ""; // Reset to default option

  }



  var SemDropdown = document.getElementById("sp_att_sem");

  if (SemDropdown) {

    SemDropdown.value = ""; // Reset to default option

  }





  var facultyDropdown = document.getElementById("sp_att_fclty");

  if (facultyDropdown) {

      facultyDropdown.value = ""; // Reset to default option

  }



  // Reset the Club dropdown

  var clubDropdown = document.getElementById("sp_att_house");

  if (clubDropdown) {

      clubDropdown.value = ""; // Reset to default option

  }



  $("#view_special_attendance").html('<tr><td colspan="4">No record(s) found.</td></tr>');



 }



 function get_club_list() {

  var usePath           = $.trim( $("#rootXPath").val() );

  var semester = $.trim( $("#sp_att_sem").val() );

  var year = $.trim( $("#sp_att_date").val() );

  var course = $.trim( $("#sp_att_crse").val() );

  var faculty = $.trim( $("#sp_att_fclty").val() );

  var dateValue = $.trim($("#sp_att_date").val());

  var year = ""; // Initialize year as an empty string



  if (dateValue) {

      // Assuming the date is in the format 'dd-MMM-YYYY' (e.g., '25-Dec-2025')

      var dateParts = dateValue.split('-');

      if (dateParts.length === 3) {

          year = dateParts[2]; // Extract the year part

      }

    }

    $.ajax({

      url: usePath + "special_attendance_params/ajax_process",

      type: 'POST',

      data: {

          identity: 'BRINGCLUB',

          "year": year,

          "course": course,

          "semester": semester,

          "faculty": faculty

      },

      async: false,

      success: function (resp) {

          var vhtml = '<option value="">-Select-</option>'; // Default option

          if (resp && resp.status && resp.club && resp.club_name) {

              vhtml += '<option value="' + resp.club + '">' + resp.club_name + '</option>';

          }else {

            console.log("No valid data returned");

        }

          $('#sp_att_house').html(vhtml); // Populate the dropdown

      },

      error: function () {

          console.error('Error fetching club data');

      },

      cache: false

  });

}


function common_Acitivity_function(){
  setTimeout(function(){ show_student_list();},500);
  setTimeout(function(){ activity_smart_search();},500);
}
function show_student_list() {
  var usePath = $("#rootXPath").val();
  var formData = new FormData();
  var sp_att_date     = $.trim( $("#sp_att_date").val() );
  var sp_att_crse     = $.trim( $("#sp_att_crse").val() );
  var sp_att_sem      = $.trim( $("#sp_att_sem").val() );
  var sp_att_fclty    = $.trim( $("#sp_att_fclty").val() );
  var sp_att_house    = $.trim( $("#sp_att_house").val() );
  var sp_att_actvty   = $.trim( $("#sp_att_actvty").val() );
  formData.append("identity", "BRINGSTUDENTLIST");
  formData.append("sp_att_date", sp_att_date);
  formData.append("sp_att_crse", sp_att_crse);
  formData.append("sp_att_sem", sp_att_sem);
  formData.append("sp_att_fclty", sp_att_fclty);
  formData.append("sp_att_house", sp_att_house);

  
  $.ajax({
    url: usePath + "subject_list/ajax_process",
    type: 'POST',
    data: formData,
    processData: false,
    contentType: false,
    success: function(resp) {
      if (resp.status) {
        //clear_fee_fields();
        $("#view_special_attendance").html(resp.data);

      } else {
        //showToaster( resp.message);
        $("#view_special_attendance").html('<tr><td colspan="4">No record(s) found.</td></tr>');

      }
    },
    error: function(xhr, status, error) {
      showToast('error', "An error occurred :" + error);

      
    }
  });

}

let searchTimeout;

function activity_smart_search() {
    clearTimeout(searchTimeout); // Clear any previous timeout

    searchTimeout = setTimeout(() => {
        var usePath = $.trim($("#rootXPath").val());
        var sp_att_actvty = $.trim($("#sp_att_actvty").val());
        var sp_att_date     = $.trim( $("#sp_att_date").val() );
        var sp_att_crse     = $.trim( $("#sp_att_crse").val() );
        var sp_att_sem      = $.trim( $("#sp_att_sem").val() );
        var sp_att_fclty    = $.trim( $("#sp_att_fclty").val() );
        var sp_att_house    = $.trim( $("#sp_att_house").val() );
       
            $(".load_employee").removeClass("hidden");

            $.ajax({
                url: usePath + "subject_list/ajax_process",
                type: 'POST',
                data: {
                    'sp_att_date':sp_att_date,
                    'sp_att_crse':sp_att_crse,
                    'sp_att_sem':sp_att_sem,
                    'sp_att_fclty':sp_att_fclty,
                    'sp_att_house':sp_att_house,
                    'identity': 'ACTIVITYSEARCH'
                },
                success: function (resp) {
                    $(".load_employee").addClass("hidden");
                    var nhtml = '';

                    if (resp.status) {
                        nhtml += '<select id="new_activity_select" onchange="selected_activity(this.value);"><option value="">-Select-</option>';
                        $.each(resp.data, function (key, leds) {
                            nhtml += `<option value="${leds.sp_att_actvty}">${leds.sp_att_actvty}</option>`;
                        });
                        nhtml += '</select>';
                    }
                    $("#activity_name").html(nhtml);
                },
                error: function () {
                    $("#activity_name").html('');
                    $(".load_employee").addClass("hidden");
                },
                cache: false
            });
        
    }, 200); // Wait 500ms after last keystroke
}


function selected_activity(val){            
  if (val !== '') {
    // Set the selected value in the input box
    $("#sp_att_actvty").val(val);
    
    // Optionally clear the dropdown if needed
    $("#activity_name").html('');
    show_student_list();

}}



// Define the function to check/uncheck all period checkboxes

function check_all_checkbox(i) {

  // Select the state of the "allperiod" checkbox (checked or unchecked)

  var isChecked = $('#allperiod' + i).prop('checked');

  

  // Loop through all the period checkboxes for the specific student index (i)

  for (var j = 1; j <= 8; j++) {

    $('#sp_att_prd' + j + i).prop('checked', isChecked); // Set the checked state based on "allperiod"

  }

}



function isNumberMyKeys(evt) {

  evt = (evt) ? evt : window.event;

  var charCode = (evt.which) ? evt.which : evt.keyCode;

  if (charCode > 31 && (charCode < 48 || charCode > 57)) {

      return false;

  }

  return true;

}


function special_attendance_download_excel(){
  var usePath      = $.trim( $("#rootXPath").val() );
  var printexcelpath = $.trim( $("#productexeclurl").attr("rel") );
  var sp_att_date = $.trim( $("#sp_att_date").val() );
  var sp_att_crse = $.trim( $("#sp_att_crse").val() );
  var sp_att_sem  = $.trim( $("#sp_att_sem").val() );
  var sp_att_fclty = $.trim( $("#sp_att_fclty").val() );
  var sp_att_house = $.trim( $("#sp_att_house").val() );
  var sp_att_actvty  = $.trim( $("#sp_att_actvty").val() );

   $.ajax({
            url: usePath+"special_attendance/ajax_process",
            type: 'POST',
            data: {'identity':'Y','sp_att_date':sp_att_date,'sp_att_crse':sp_att_crse,'sp_att_sem':sp_att_sem,'sp_att_fclty':sp_att_fclty,'sp_att_house':sp_att_house,'sp_att_actvty':sp_att_actvty},
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