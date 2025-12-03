function alertChecked(url){
    if( confirm("Are you sure want to delete ?")){
        window.location = url
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
  $(document).on("keypress","#subject_list",function(e){
    var keycode = (e.keyCode ? e.keyCode : e.which );
      if( keycode == '13' ){
        filter_subject_list();
      }
  
  });
  function filter_subject_list(){
      var useroot = $("#rootXPath").val();
     
      $(".show_loader").removeClass("hidden");
      $(".no_loader").removeClass("hidden").addClass("hidden")
      $("form#myForms").submit(); 
  
  }
  function updateSemesters() {
    var usePath = $.trim($("#rootXPath").val());
    var course_code = $.trim($("#sub_crse").val());
    var selectedSemester = $("#sub_sem").data("selected-semester"); // Get the preselected semester

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



