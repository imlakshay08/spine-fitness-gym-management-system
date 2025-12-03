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

 
  function attendance_report_download_excel(){
    var usePath      = $.trim( $("#rootXPath").val() );
    var printexcelpath = $.trim( $("#productexeclurl").attr("rel") );
    var report_course = $.trim( $("#report_course").val() );
    var from_date = $.trim( $("#from_dated").val() );
    var upto_date = $.trim( $("#upto_dated").val() );
    var report_semester = $.trim( $("#sub_sem").val() );
    var report_type    = $.trim( $("#report_type").val() );
    var report_club    = $.trim( $("#report_club").val() );

    $(".no_loader").removeClass("hidden").addClass("hidden");
    $(".loader").removeClass("hidden");  
     setTimeout(function(){
     $.ajax({
              url: usePath+"attendance_reports/ajax_process",
              type: 'POST',
              data: {'identity':'Y','asondated':from_date,'uptodated':upto_date,'report_course':report_course,'report_semester':report_semester,'report_type':report_type,'report_club':report_club},
              async: false,
              success: function (resp) {
                       if( resp.status){
                        $(".no_loader").removeClass("hidden");
                        $(".loader").removeClass("hidden").addClass("hidden"); 
                          window.open(printexcelpath, '_blank');
                     }else{
                        $(".no_loader").removeClass("hidden");
                        $(".loader").removeClass("hidden").addClass("hidden"); 
                      alert("No record(s) found.");
                    }
              },
              error: function () {
                $(".no_loader").removeClass("hidden");
                $(".loader").removeClass("hidden").addClass("hidden"); 
              },  
              cache: false

     });
      },200);
  
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

function get_report_type(){
    var report_type       = $.trim($("#report_type").val());
    if (report_type == 'C' || report_type == 'I' || report_type == 'S' || report_type == 'F') {
        $("#fromdate_uptodate").removeClass("hidden");
       
    } else {
        $("#fromdate_uptodate").addClass("hidden");
    }
    if (report_type == 'S'){
        $("#club_dropdown").removeClass("hidden");
    }else {
        $("#club_dropdown").addClass("hidden");
    }
}

