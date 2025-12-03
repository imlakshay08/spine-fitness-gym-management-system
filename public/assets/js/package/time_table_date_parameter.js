$(document).ready(function(){



    flatpickr("#tt_dtp_fromdate", {

  

      dateFormat: "d-M-Y",

  

      allowInput: true,

  

      onOpen: function (selectedDates, dateStr, instance) {

  

        instance.setDate(instance.input.value, false);

  

      },

  

    });

  

  });



  $(document).ready(function(){



    flatpickr("#tt_dtp_uptodate", {

  

      dateFormat: "d-M-Y",

  

      allowInput: true,

  

      onOpen: function (selectedDates, dateStr, instance) {

  

        instance.setDate(instance.input.value, false);

  

      },

  

    });

  

  });



  function updateSemester() {

    var usePath           = $.trim($("#rootXPath").val());

    var course_code       = $.trim($("#tt_dtp_course").val());

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

    var year = $.trim( $("#tt_dtp_year").val() );

    var course = $.trim( $("#tt_dtp_course").val() );



    $.ajax({

        url: usePath+"time_table_date_parameter/ajax_process",

        type: 'POST',

        data: { identity: 'BRINGDATE',

          "year": year,

          "course": course,

          "semester": semester},

        async: false,

        success: function (resp) {



          if (resp && resp.status) {



            $('#tt_dtp_fromdate').val(resp.from_date);

            $('#tt_dtp_uptodate').val(resp.upto_date);

        }

        },

        error: function () {

            console.error('Error fetching semesters');

        },

        cache: false

    });

  }



  function process_save_time_table_date_params(){

    var usePath           = $.trim( $("#rootXPath").val() );

    var formData          = new FormData();

    var other_data        = $('form#myforms').serializeArray();

    var mid               = $.trim( $("#mid").val() ); 

    var tt_dtp_year      = $.trim( $("#tt_dtp_year").val() );

    var tt_dtp_course    = $.trim( $("#tt_dtp_course").val() );

    var sub_sem       = $.trim( $("#sub_sem").val() ); 

    var tt_dtp_fromdate         = $.trim( $("#tt_dtp_fromdate").val() );

    var tt_dtp_uptodate      = $.trim( $("#tt_dtp_uptodate").val() );

    var timetabledtparamId      = $.trim( $("#timetabledtparamId").val() );



    if( tt_dtp_year == ''){

      showToast("error","Year is required.");

      setTimeout(function(){ set_global_focus('tt_dtp_year');},500);

      return false;

    }else if( tt_dtp_course == ''){

      showToast("error","Course is required.");

      setTimeout(function(){ set_global_focus('tt_dtp_course');},500);

      return false;

    }else if( sub_sem == ''){

      showToast("error","Semester is required.");

      setTimeout(function(){ set_global_focus('sub_sem');},500);

      return false;

    }else if( tt_dtp_fromdate == ''){

      showToast("error","From Date is required.");

      setTimeout(function(){ set_global_focus('tt_dtp_fromdate');},500);

      return false;

    }else if( tt_dtp_uptodate == ''){

      showToast("error","Upto Date is required.");

      setTimeout(function(){ set_global_focus('tt_dtp_uptodate');},500);

      return false;

    }

    formData.append("identity", "TIMETABLEDATEPARAM");

    formData.append("mid", mid);  

    formData.append("timetabledtparamId", timetabledtparamId);  



    $.each(other_data,function(key,input){

        formData.append(input.name,input.value);

    });

    

     $(".no_loader").removeClass("hidden").addClass("hidden");

     $(".loader").removeClass("hidden");

      setTimeout(function(){

    $.ajax({

            url: usePath+"time_table_date_parameter/ajax_process",

            type: 'POST',

            data: formData,

            async: false,

            contentType: false,

            processData: false,

            success: function (resp) {

              

              if( resp.status ){

                $("#mid").val(resp.profileid);                       

                alert(resp.message);

                $("#timetabledtparamId").val('');

                $("#mid").val('');

                $("#tt_dtp_uptodate").val('');

                $("#tt_dtp_fromdate").val('');     

                $("#sub_sem").val('');

                $("#tt_dtp_course").val('');

                $("#tt_dtp_year").val('');                   

                window.location = usePath+"time_table_date_parameter";      

              }else{  

                $(".no_loader").removeClass("hidden");

                 $(".loader").removeClass("hidden").addClass("hidden");                         

                alert(resp.message); 

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





