
function print_contract_report_excel(){
  var usePath       = $.trim( $("#rootXPath").val() );
  var report_course   = $.trim($("#report_course").val());
  var report_semester       = $.trim($("#sub_sem").val());
  var report_year    = $.trim($("#report_year").val());
  var report_month  = $.trim($("#report_month").val());
  var report_subject      = $.trim($("#report_subject").val());

  var printurl     = $.trim( $("#printexcel").attr("rel") );

//    var chekexcel    = ""
//     if( $("input[name='report_type']").is(":checked")){
//         chekexcel = $("input[name='report_type']:checked").val();
//     }

    if(report_course == ''){
    showToast("info","Please select Course.");
    return false;
  }
  
  if(report_semester == ''){
    showToast("info","Please select Semester");
    return false;
  }
  
  if(report_year == ''){
    showToast("info","Please select Year");
    return false;
  }
  if(report_month == ''){
    showToast("info","Please select Month");
    return false;
  }
  if(report_subject == ''){
    showToast("info","Please select Subject");
    return false;
  }
        $(".show_loader").removeClass("hidden");
        $(".no_loader").removeClass("hidden").addClass("hidden");
   $.ajax({

               url: usePath+"faculty_attendance_report/ajax_process",
               type: 'POST',
               data: {'report_course':report_course,'report_semester':report_semester,'report_year':report_year,'report_month':report_month,'report_subject':report_subject,'identity':'PRNTCONTRACT'},
               async: false,
               success: function (resp) {
                    $(".show_loader").removeClass("hidden").addClass("hidden");
                    $(".no_loader").removeClass("hidden");
                    if(resp.status){
                        window.open(printurl, '_blank');
                    }else{
                        alert("No record(s) found.");
                        return false;
                    }
               },
               error: function () {
                    $(".show_loader").removeClass("hidden").addClass("hidden");
                    $(".no_loader").removeClass("hidden");
               },
               cache: false
       });
}

function updateSemester() {
    var usePath           = $.trim($("#rootXPath").val());
    var course_code       = $.trim($("#report_course").val());
    var selectedSemester  = $("#sub_sem").data("selected-semester"); // Get the preselected semester
    var faculty = $.trim( $("#sp_attp_faculty").val() );
    var club = $.trim( $("#sp_attp_club").val() );

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

  

function update_subject_list() {
  var usePath   = $.trim( $("#rootXPath").val() );
  var course_id = $('#report_course').val() ? $('#report_course').val() : 0;
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
      $('#report_subject').html('<option value="">Select...</option>');
  }
}

function update_subject_dropdown(subjects) {
  var subjectDropdown = $('#report_subject');
  subjectDropdown.empty();
  subjectDropdown.append('<option value="">-Select-</option>');
  
  if (subjects && subjects.length > 0) {
      $.each(subjects, function(index, subject) {
          subjectDropdown.append('<option value="' + subject.id + '">' + subject.sub_code + ' - ' + subject.sub_name +  '</option>');
      });
  }
}