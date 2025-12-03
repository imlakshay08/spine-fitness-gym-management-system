function process_save_special_attendance_params(){
    var usePath             = $.trim( $("#rootXPath").val() );
    var formData            = new FormData();
    var other_data          = $('form#myforms').serializeArray();
    var mid                 = $.trim( $("#mid").val() ); 
    var sp_attp_year        = $.trim( $("#sp_attp_year").val() );
    var sp_attp_course      = $.trim( $("#sp_attp_course").val() );
    var sub_sem             = $.trim( $("#sub_sem").val() ); 
    var sp_attp_faculty     = $.trim( $("#sp_attp_faculty").val() );
    var sp_attp_club        = $.trim( $("#sp_attp_club").val() );
    var specialAttendParamId= $.trim( $("#specialAttendParamId").val() );

    if( sp_attp_year == ''){
      showToast("error","Year is required.");
      setTimeout(function(){ set_global_focus('sp_attp_year');},500);
      return false;
    }else if( sp_attp_course == ''){
      showToast("error","Course is required.");
      setTimeout(function(){ set_global_focus('sp_attp_course');},500);
      return false;
    }else if( sub_sem == ''){
      showToast("error","Semester is required.");
      setTimeout(function(){ set_global_focus('sub_sem');},500);
      return false;
    }else if( sp_attp_faculty == ''){
      showToast("error","Faculty is required.");
      setTimeout(function(){ set_global_focus('sp_attp_faculty');},500);
      return false;
    }else if( sp_attp_club == ''){
      showToast("error","Club is required.");
      setTimeout(function(){ set_global_focus('sp_attp_club');},500);
      return false;
    }
    formData.append("identity", "SPECIALATTENDPARAM");
    formData.append("mid", mid);  
    formData.append("specialAttendParamId", specialAttendParamId);  

    $.each(other_data,function(key,input){
        formData.append(input.name,input.value);
    });
    
     $(".no_loader").removeClass("hidden").addClass("hidden");
     $(".loader").removeClass("hidden");
      setTimeout(function(){
    $.ajax({
            url: usePath+"special_attendance_params/ajax_process",
            type: 'POST',
            data: formData,
            async: false,
            contentType: false,
            processData: false,
            success: function (resp) {
              
              if( resp.status ){
                $("#mid").val(resp.profileid);                       
                alert(resp.message); 
                $("#specialAttendParamId").val('');
                $("#mid").val('')
                $("#sp_attp_year").val('');
                $("#sp_attp_course").val('');     
                $("#sub_sem").val('');
                $("#sp_attp_faculty").val('');
                $("#sp_attp_club").val('');
                window.location = usePath+"special_attendance_params"
              }else{  
                $(".no_loader").removeClass("hidden");
                 $(".loader").removeClass("hidden").addClass("hidden");                         
                showToast("success",resp.message); 
              }
  
            },
            error: function () {
              $(".no_loader").removeClass("hidden");
              $(".loader").removeClass("hidden").addClass("hidden");
                $(".process_save").show();
            },
            cache: false
             });
  
      },500);
  }
  function get_club_list() {
    var usePath           = $.trim( $("#rootXPath").val() );
    var semester = $.trim( $("#sub_sem").val() );
    var year = $.trim( $("#sp_attp_year").val() );
    var course = $.trim( $("#sp_attp_course").val() );
    var faculty = $.trim( $("#sp_attp_faculty").val() );

    $.ajax({
        url: usePath+"special_attendance_params/ajax_process",
        type: 'POST',
        data: { identity: 'BRINGCLUB',
          "year": year,
          "course": course,
          "semester": semester,
          "faculty":faculty},
        async: false,
        success: function (resp) {

          if (resp && resp.status) {

            $('#sp_attp_club').val(resp.club);
        }
        },
        error: function () {
            console.error('Error fetching semesters');
        },
        cache: false
    });
  }
  function updateSemester() {
    var usePath           = $.trim($("#rootXPath").val());
    var course_code       = $.trim($("#sp_attp_course").val());
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

  function empty_faculty_club(){
   // Reset the Faculty dropdown
   var facultyDropdown = document.getElementById("sp_attp_faculty");
   if (facultyDropdown) {
       facultyDropdown.value = ""; // Reset to default option
   }

   // Reset the Club dropdown
   var clubDropdown = document.getElementById("sp_attp_club");
   if (clubDropdown) {
       clubDropdown.value = ""; // Reset to default option
   }
  }

  function alertChecked(url){
    if( confirm("Are you sure want to delete ?")){
        window.location = url
    }
  }