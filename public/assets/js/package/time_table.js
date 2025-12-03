function save_time_table() {
    var usePath              = $.trim( $("#rootXPath").val() );
    var formData             = new FormData();
    var other_data           = $('form#myforms').serializeArray();
    var mid                  = $.trim( $("#timetableid").val() );
    var year                 = $.trim( $("#tt_year").val() );	
    var subject              = $.trim( $("#tt_subject").val() );
    var day                  = $.trim( $("#tt_day").val() );	
    var period               = $.trim( $("#tt_period").val() );
    var faculty              = $.trim( $("#tt_faculty").val() );	
    var group                = $.trim( $("#tt_group").val() );
    var course               = $.trim( $("#tt_course").val() );
    var sub_sem              = $.trim( $("#sub_sem").val() );
    
    if (year == '') {
     
      showToast('warning', 'Year is required.');
      $("#tt_year").focus();
      return false;
    }else if (course == '') {
      showToast('warning', 'Course is required.');
      $("#tt_course").focus();
      return false;  
    }else if (sub_sem == '') {
      showToast('warning', 'Semester is required.');
      $("#sub_sem").focus();
      return false;  
  } else if (subject == '') {
      showToast('warning', 'Subject is required.');
      $("#tt_subject").focus();
      return false;
  }else if (day == '') {
    showToast('warning', 'Day is required.');
    $("#tt_day").focus();
    return false;
  }else if (period == '') {
    showToast('warning', 'Period is required.');
    $("#tt_period").focus();
    return false;
  }else if (faculty == '') {
    showToast('warning', 'Faculty is required.');
    $("#tt_faculty").focus();
    return false;
  }else if (group == '') {
    showToast('warning', 'Group is required.');
    $("#tt_group").focus();
    return false;
  }
    $.each(other_data,function(key,input){
      formData.append(input.name,input.value);
  });   

    formData.append("identity", "TIMETABLE");  
    formData.append("timetableid", mid);
    //formData.append("tt_year", tt_year);
    $.each(other_data,function(key,input){
        formData.append(input.name,input.value);
    });
    
     $(".process_qualif_save").hide();
      $.ajax({
             url: usePath+"time_table/ajax_process",
             type: 'POST',
             data: formData,
             async: false,
             contentType: false,
             processData: false,
             success: function (resp) {
               
                if( resp.status ){
                    showToast("success", resp.message);
                    $("#process_time_table").html(resp.data);
                    setTimeout(function(){ reset_qualification_afteradd(); },500);
                      
                   
                }else{
                    $(".process_qualif_save").show();
                    showToast("warning", resp.message);                  
                }
             },
             error: function () {
                 $(".process_qualif_save").show();
             },
             cache: false
     });
  }

  function reset_qualification_afteradd(){
    $("#timetableid").val('');
    //$("#tt_year").val('')
    $("#tt_day").val('');
    $("#tt_period").val('') ;
    $("#tt_faculty").val('');
   $("#tt_group").val('');
      $("#tt_subject").val('');

  }

  // Toastr Custom Function
  function showToast(type, message, heading = '', position = 'top-center', hideAfter = 3000) {
    $.toast({
        heading: heading, // Optional title for the toast
        text: message,    // Main message text
        showHideTransition: 'fade', // Transition effect ('plain', 'fade', or 'slide')
        icon: type,       // Type: 'info', 'success', 'warning', or 'error'
        position: position, // Position: 'top-right', 'top-left', 'bottom-right', 'bottom-left'
        hideAfter: hideAfter, // Duration before auto-hiding the toast (in milliseconds)
        stack: false,     // Allow only one toast at a time
        loader: true,     // Enable the progress bar
        loaderBg: '#9EC600' // Progress bar color
    });
}

$(document).on("keypress","#tt_subject",function(e){
  var keycode = (e.keyCode ? e.keyCode : e.which );
    if( keycode == '13' ){
      filter_time_table();
    }

});
function filter_time_table(){
    var useroot = $("#rootXPath").val();
    $(".show_loader").removeClass("hidden");
    $(".no_loader").removeClass("hidden").addClass("hidden")
    $("form#myforms").attr("action",useroot+"time_table/search");
    $("form#myForms").submit(); 

}

function get_time_table_sheet_list(){
    var usePath              = $.trim( $("#rootXPath").val() );
    var formData             = new FormData();
    //var other_data           = $('form#myforms').serializeArray();     
    var subject              = $.trim( $("#tt_subject").val() );   
    var tt_year              = $.trim( $("#tt_year").val() );
    var tt_group             = $.trim( $("#tt_group").val() );
    var tt_course            = $.trim( $("#tt_course").val() );
    var sub_semster         = $.trim( $("#sub_sem").val() );

    formData.append("identity", "VWTIMETABLE");
    formData.append("tt_year", tt_year);
    formData.append("tt_subject", subject);
    formData.append("tt_group", tt_group);
    formData.append("tt_course", tt_course);
    formData.append("sub_semster", sub_semster);

      $.ajax({
             url: usePath+"time_table/ajax_process",
             type: 'POST',
             data: formData,
             async: false,
             contentType: false,
             processData: false,
             success: function (resp) { 
                var ntml = '<tr><td colspan="4">No record(s) found.</td></tr>'          
                if( resp.status ){
                   $("#process_time_table").html(resp.data);                        
                }else{
                  $("#process_time_table").html(ntml); 
                }
             },
             error: function () {
                 
             },
             cache: false
     });
}

function view_faculty_time_table(){
  var usePath              = $.trim( $("#rootXPath").val() );
  var formData             = new FormData();
  //var other_data         = $('form#myforms').serializeArray();     
  var tt_faculty           = $.trim( $("#tt_faculty").val() );   
  var tt_year              = $.trim( $("#tt_year").val() );

  formData.append("identity", "FACULTYIMETABLE");
  formData.append("tt_year", tt_year);
  formData.append("tt_faculty", tt_faculty);

    $.ajax({
           url: usePath+"time_table/ajax_process",
           type: 'POST',
           data: formData,
           async: false,
           contentType: false,
           processData: false,
           success: function (resp) { 
              var ntml = '<tr><td colspan="4">No record(s) found.</td></tr>'          
              if( resp.status ){
                 $("#process_time_table").html(resp.data);                        
              }else{
                $("#process_time_table").html(ntml); 
              }
           },
           error: function () {
               
           },
           cache: false
   });
}

function common_process_requested(){
  setTimeout(function(){ update_subject_list(); },500);
  setTimeout(function(){ get_time_table_sheet_list(); },500); 
  setTimeout(function(){ get_from_upto_dates(); },500);
}


function process_delete_time_sheet(days,period,year,group,sub_semster){
  var usePath = $.trim( $("#rootXPath").val() );
  var courses = $.trim( $("#tt_course").val() );
  var group = $.trim( $("#tt_group").val() );
  var sub_semster   = $.trim( $("#sub_sem").val() );
    if( confirm("Do you want to delete this record?")){
          $.ajax({
            url: usePath+"time_table/ajax_process",
            type: 'POST',
            data: {
                identity: 'DELTIMESHEET',
                days: days,
                period:period,
                year:year,
                group:group,
                courses:courses,
                sub_semster:sub_semster
            },
            success: function(response) {
                if( response.status){
                  setTimeout(function(){ get_time_table_sheet_list(); },500);
                }else{
                  showToast("warning", response.message);     
                }
              
            },
            error: function() {
            
            }
        });
    }
}


function update_subject_list() {
  var usePath   = $.trim( $("#rootXPath").val() );
  var course_id = $('#tt_course').val() ? $('#tt_course').val() : 0;
  var sub_sem   = $('#sub_sem').val() ? $('#sub_sem').val() : 0 ;

  if( course_id >0 && sub_sem >0 ) {
      $.ajax({
          url: usePath+"time_table/ajax_process",
          type: 'POST',
          data: {
              identity: 'COURSESUBJECTS',
              course_id: course_id,
              sub_sem:sub_sem
          },
          success: function(response) {
              update_subject_dropdown(response.subjects);
          },
          error: function(xhr, status, error) {
              console.log("Error fetching subjects: " + error);
          }
      });
  } else {
      $('#tt_subject').html('<option value="">Select...</option>');
  }
}

function update_subject_dropdown(subjects) {
  var subjectDropdown = $('#tt_subject');
  subjectDropdown.empty();
  subjectDropdown.append('<option value="">-Select-</option>');
  
  if (subjects && subjects.length > 0) {
      $.each(subjects, function(index, subject) {
          subjectDropdown.append('<option value="' + subject.id + '">' + subject.sub_code + ' - ' + subject.sub_name +  '</option>');
      });
  }
}

function fill_from_subject() {
  var usePath = $.trim($("#rootXPath").val());
  var course = $.trim($("#tt_subject").val());

  if (course === "") {
      // Do nothing if no subject is selected
      return;
  }
  $.ajax({
      url: usePath + "time_table/ajax_process",
      type: 'POST',
      data: {'course': course, 'requesttype': 'CODE', 'identity': 'SUBJECT'},
      async: false,
      success: function (resp) {
          if (resp.status) {
              var sdata = resp.data;
              $("#typ").text(sdata.typ);
              $("#subject-details-card").show();
              if (sdata.typ === "Theory" || sdata.typ === "Practical") {
                fill_group_dropdown(sdata.typ);
            }
          } else {
              // Clear values if no record found
              
              $("#typ").text('');
              
              alert("No record(s) found.");
          }
      },
      error: function () {
          // Clear values on error
         
          $("#typ").text('');
      },
      cache: false
  });
}

function fill_group_dropdown(subjectType) {
var groupDropdown = $("#tt_group");
groupDropdown.empty(); // Clear existing options
groupDropdown.append('<option value="">-Select-</option>');

if (subjectType === "Theory") {
    var theoryGroups = ["1", "2", "3", "4", "5"];
    $.each(theoryGroups, function (index, group) {
        groupDropdown.append(`<option value="${group}">${group}</option>`);
    });
} else if (subjectType === "Practical") {
    var practicalGroups = ["A", "B", "C", "D", "E", "F", "G", "H"];
    $.each(practicalGroups, function (index, group) {
        groupDropdown.append(`<option value="${group}">${group}</option>`);
    });
} else {
    groupDropdown.append('<option value="">-Select-</option>');
}
}

function updateSemesters() {
  var usePath           = $.trim($("#rootXPath").val());
  var course_code       = $.trim($("#tt_course").val());
  var selectedSemester  = $("#sub_sem").data("selected-semester"); // Get the preselected semester

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
          $("#sub_sem").html(vhtml);
      },
      error: function () {
          console.error('Error fetching semesters');
      },
      cache: false
  });
}

function get_from_upto_dates() {
  var usePath           = $.trim( $("#rootXPath").val() );
  var semester = $.trim( $("#sub_sem").val() );
  var year = $.trim( $("#tt_year").val() );
  var course = $.trim( $("#tt_course").val() );
  $.ajax({
      url: usePath+"time_table/ajax_process",
      type: 'POST',
      data: { identity: 'BRINGDATE',
        "year": year,
        "course": course,
        "semester": semester},
      async: false,
      success: function (resp) {

        if (resp && resp.status) {
          if (resp.data != null){
            $("#date-details-card").show();
          $('#tt_dtp_fromdate').text(resp.from_date);
          $('#tt_dtp_uptodate').text(resp.upto_date);
        }
        else{
          $("#date-details-card").hide();
        }
          }
      else{
      $("#date-details-card").hide();
    }
      },
      error: function () {
          console.error('Error fetching semesters');
      },
      cache: false
  });
}