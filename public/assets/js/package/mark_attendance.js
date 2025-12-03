$(document).ready(function(){

    flatpickr("#att_date", {

      dateFormat: "d-M-Y",

      allowInput: true,

      onOpen: function (selectedDates, dateStr, instance) {

        instance.setDate(instance.input.value, false);

      },

    });

  });



  function fill_from_subject() {

    var usePath = $.trim($("#rootXPath").val());

    var course = $.trim($("#att_subject").val());

    $("#subject-details-card").hide();

    clearStudentTable();



    if (course === "") {

        return;

    }



    $.ajax({

        url: usePath + "mark_attendance/ajax_process",

        type: 'POST',

        data: {'course': course, 'requesttype': 'CODE', 'identity': 'SUBJECT'},

        async: false,

        success: function (resp) {

            if (resp.status) {

                var sdata = resp.data;

                var course = resp.course;

                var coursename = course.crse_descp;



                // Fill in course, semester, type, period, and group details

                $("#course_text").text(coursename);

                $("#semester").text(sdata.semester + " Semester");

                $("#typ").text(sdata.typ);

                $("#subject-details-card").show();



                // Populate period and group dropdowns

                fill_period_dropdown(sdata.period);

                fill_group_dropdown(sdata.group);



            } else {

                $("#course_text").text('');

                $("#semester").text('');

                $("#typ").text('');

                alert("No record(s) found.");

            }

        },

        error: function () {

            $("#course_text").text('');

            $("#semester").text('');

            $("#typ").text('');

        },

        cache: false

    });

}



function fill_period_dropdown(period) {

    $("#att_period").empty().append("<option value=''>Select...</option>");

    if (period) {

        $("#att_period").append(`<option value="${period}">${period}</option>`);

    }

}



function fill_group_dropdown(group) {

    $("#att_grp").empty().append("<option value=''>Select...</option>");

    if (group) {

        $("#att_grp").append(`<option value="${group}">${group}</option>`);

    }

}



function fetchStudentsForGroup(selectedGroup, faculty, date, period, att_subject,att_sem) {

  var usePath = $.trim($("#rootXPath").val());



  $.ajax({

    url: usePath + "mark_attendance/get_students_lists",

    type: 'POST',

    data: { 'group': selectedGroup, 'att_fclty': faculty, 'att_date': date, 'att_period': period, 'att_subject': att_subject, 'att_sem':att_sem},

    async: false,

    success: function(resp) {

      if (resp.status) {

        populateStudentTable(resp.students);

        $("#group").text(selectedGroup+ " Group"); // Display the first group // Function to populate the student table with attendance status

      } else {

        alert("No students found for the selected group.");

        clearStudentTable();

        $("#group").text( " Group"); // Display the first group // Function to populate the student table with attendance status

        // Function to clear the student table

      }

    },

    error: function() {

      alert("Error occurred while fetching students.");

      clearStudentTable(); // Clear the student table on error

    },

    cache: false

  });

}



function fetch_Optional_subjects_Students_from_group($groupDropdown, faculty, date, period, att_subject,att_sem) {

  var usePath = $.trim($("#rootXPath").val());

  var $groupDropdown = $.trim($("#att_grp").val());



  $.ajax({

    url: usePath + "mark_attendance/get_students_lists",

    type: 'POST',

    data: { 'group': $groupDropdown, 'att_fclty': faculty, 'att_date': date, 'att_period': period, 'att_subject': att_subject, 'att_sem':att_sem},

    async: false,

    success: function(resp) {

      if (resp.status) {

        populateStudentTable(resp.students);

        $("#group").text(' '); // Function to populate the student table with attendance status

        $("#group").text($groupDropdown +" Group"); // Function to populate the student table with attendance status

      } else {

        clearStudentTable(); // Function to clear the student table

      }

    },

    error: function() {

      clearStudentTable(); // Clear the student table on error

    },

    cache: false

  });

}





function populateStudentTable(students) {

  var tableBody = $(".table tbody");

  tableBody.empty(); 



  $.each(students, function(index, student) {

    var isChecked = student.attendance_status === 'Y' ? 'checked' : '';

    var row = `<tr>

                  <td>${index + 1}</td>

                  <td>${student.code}</td>

                  <td>${student.name}</td>

                  <td class="text-center">

                    <input type="checkbox" name="attendance[${student.code}]" value="Y" ${isChecked} style="width: 20px;height: 25px;" />

                  </td>

               </tr>`;

    tableBody.append(row);

  });

}



function saveAttendance() {

  var usePath = $.trim($("#rootXPath").val());

  var formData = new FormData();

  var other_data = $('form#myforms').serializeArray();

  var mid = $.trim($("#markAttendanceId").val());



  // Collect attendance data for each student

  $('input[name^="attendance"]').each(function() {

    var studentCode = $(this).attr('name').match(/\[(.*?)\]/)[1];

    var isChecked = $(this).is(':checked') ? 'Y' : 'N';

    formData.append(`attendance[${studentCode}]`, isChecked);

  });

  formData.append("att_subject", $("#att_subject").val()); // Include subject ID

  formData.append("identity", "ATTENDANCE");

  formData.append("markAttendanceId", mid);



    // Append other form data

    $.each(other_data, function(key, input) {

      formData.append(input.name, input.value);

    });

  



  $.ajax({

    url: usePath + "mark_attendance/ajax_process", // Updated to match the correct path for `create`

    type: 'POST',

    data: formData,

    contentType: false,

    processData: false,

    success: function(resp) {

      if (resp.status) {

        alert(resp.message); // Display success message

        window.location = usePath+"mark_attendance"

      } else {

        alert(resp.message); // Display error message

      }

    },

    error: function(xhr, status, error) {

      console.log("Error: ", error);

      alert("An error occurred while saving attendance.");

    }

  });

}



function clearStudentTable() {

  var tableBody = $(".table tbody");

  tableBody.empty();

}



function fetch_subjects_by_faculty() {

  var usePath = $.trim($("#rootXPath").val());

  var facultyId = $.trim($("#att_fclty").val());

  var selectedDate = $.trim($("#att_date").val()); // Get the selected date



  if (facultyId === "" || selectedDate === "") {

    $("#att_subject").empty().append('<option value="">Select...</option>');

    $("#att_period").empty().append('<option value="">Select...</option>');

    return;

  }



  $.ajax({

    url: usePath + "mark_attendance/ajax_process",

    type: 'POST',

    data: {

      'faculty_id': facultyId,

      'att_date': selectedDate, // Include the selected date

      'identity': 'FETCH_SUBJECTS'

    },

    async: false,

    success: function(resp) {

      if (resp.status) {

        var subjects = resp.data;

        var periods = resp.periods;



        // Populate subject dropdown

        var $subjectDropdown = $("#att_subject");

        $subjectDropdown.empty();

        $subjectDropdown.append('<option value="">-Select-</option>');

        $.each(subjects, function(index, subject) {

          $subjectDropdown.append('<option value="' + subject.id + '">' + subject.sub_code + '</option>');

        });



        // Populate period dropdown

        var $periodDropdown = $("#att_period");

        $periodDropdown.empty();

        $periodDropdown.append('<option value="">-Select-</option>');

        $.each(periods, function(index, period) {

          $periodDropdown.append('<option value="' + period + '">' + period + '</option>');

        });



        var $listContainer = $("#process_specification");

        $listContainer.empty(); // Clear previous items

        $.each(periods, function(index, period) {

          $listContainer.append(`

            <li style="display:flex;">

              <div style="width:100%;">

                <span class="float-left">Period ${period}</span>

                <span class="float-right">

                  <input type="checkbox" name="post_type_select[]" onclick="get_selected_item_val();" id="${period}" value="${period}" style="width: 20px;height: 18px;"/>

                </span>

              </div>

            </li>

            <li class="mt5 mr5" style="display: flex;">

          `);

        });

        $listContainer.append(`<li class="mt5 mr5" style="display: flex;">

                    <div style="width: 100%;">

                      <span class="float-left"></span>

                      <span class="float-right" onclick="close_profile_checkbox();">

                      <button type="button" title="Close" class="btn-close" data-bs-dismiss="modal" aria-label="Close">

                      </button>

                      </span>

                    </div>

                    </li>`);

        $("#att_grp").empty().append('<option value="">Select...</option>');

        $("#subject-details-card").hide(); 



      } else {

        alert("No subjects found for the selected faculty.");

        $("#att_period").empty().append('<option value="">Select...</option>');

        $("#att_grp").empty().append('<option value="">Select...</option>');

        $("#subject_name").text('');

        $("#group").text('');

      }

    },

    error: function() {

      alert("An error occurred while fetching subjects.");

    },

    cache: false

  });

}



function fetch_groups_by_period() {

  var usePath = $.trim($("#rootXPath").val());

  var facultyId = $.trim($("#att_fclty").val());

  var selectedDate = $.trim($("#att_date").val()); // Get the selected date

  var selectedPeriod = $.trim($("#att_period").val()).split(","); // Get the selected period



  if (selectedPeriod.length === 0 || !selectedPeriod[0]) {

    $("#att_grp").empty().append('<option value="">Select...</option>');

    $("#subject_name").text('');

    $("#group").text('');

    $("#typ").text('');

    return;

  }



  $.ajax({

    url: usePath + "mark_attendance/ajax_process",

    type: 'POST',

    data: {

      'faculty_id': facultyId,

      'att_date': selectedDate, // Include the selected date

      'att_period': selectedPeriod,

      'identity': 'FETCH_GROUPS' // Defined to identify the request

    },

    async: false,

    success: function(resp) {

      if (!resp.status) {

        alert(resp.message || "An error occurred.");

        $("#att_grp").empty().append('<option value="">Select...</option>');

        $("#subject_name").text('');

        $("#group").text('');

        $("#typ").text('');

        return;

      }

    

      if (selectedPeriod.length > 1) {  // Only validate when multiple periods are selected

        const firstSubject = resp.subjects[0];

        const firstGroup = resp.groups[0];



        for (let i = 1; i < resp.subjects.length; i++) {

          if (resp.subjects[i].sub_name !== firstSubject.sub_name || resp.groups[i] !== firstGroup) {

            alert("All selected periods must have the same subject and group!");

            $("#att_grp").empty().append('<option value="">Select...</option>');

            $("#subject_name").text('');

            $("#group").text('');

            $("#typ").text('');

            return;

          }

        }

      }

      var $groupDropdown = $("#att_grp");

      $groupDropdown.empty();

      const subject = resp.subjects[0];

      const isOptional = subject.sub_isoptional === "Y"; // Check if the value is "Y"

      const optionalText = isOptional ? "Optional" : "";  



      if(!isOptional){

      if (resp.groups && resp.groups.length > 0) {

        $.each(resp.groups, function(index, group) {

          if (group) {

            $groupDropdown.append('<option value="' + group + '">' + group + '</option>');

            

            // Call fetchStudentsForGroup with additional parameters

            fetchStudentsForGroup(group, facultyId, selectedDate, selectedPeriod, resp.subject_id, resp.att_sem);

          }

        });

      } else {

        alert("No groups found for the selected period.");

        $("#att_grp").empty().append('<option value="">Select...</option>');

        $("#subject_name").text('');

        $("#typ").text(''); 

        $("#group").text(''); // Clear group text

        $("#subject-details-card").hide();



      }



      // Display the subject and group in respective divs

      if (resp.subjects && resp.subjects.length > 0) {

        // Assuming you want to display the first subject

        $("#subject-details-card").show();                                                            

        $("#subject_name").text(resp.subjects[0].sub_name + ' ' + resp.subjects[0].sub_code);

        $("#typ").text(''); 

        $("#group").text(resp.groups[0] + " Group"); // Display the first group

        $("#att_subject").val(resp.subjects[0].id);

        $("#att_sem").val(resp.subjects[0].sub_sem);

        $("#att_crse").val(resp.subjects[0].sub_crse);

      }

    }

    else{

      if (resp.groups && resp.groups.length > 0) {

        $("#att_grp").empty().append('<option value="">-Select-</option>');

        $.each(resp.groups, function(index, group) {

          if (group) {

            $groupDropdown.append('<option value="' + group + '">' + group + '</option>');

          }

        });

        $("#att_grp").change(function() {

          fetch_Optional_subjects_Students_from_group($groupDropdown, facultyId, selectedDate, selectedPeriod, resp.subject_id, resp.att_sem);

        });

      } else {

        $("#att_grp").empty().append('<option value="">Select...</option>');

        $("#subject_name").text('');

        $("#typ").text(''); 

        $("#group").text(''); // Clear group text

        $("#subject-details-card").hide();



      }



      // Display the subject and group in respective divs

      if (resp.subjects && resp.subjects.length > 0) {

        // Assuming you want to display the first subject

        $("#subject-details-card").show();                                                            

        $("#subject_name").text(resp.subjects[0].sub_name + ' ' + resp.subjects[0].sub_code);

        $("#typ").text(optionalText); 

        $("#group").text( " Group"); // Display the first group

        $("#att_subject").val(resp.subjects[0].id);

        $("#att_sem").val(resp.subjects[0].sub_sem);

        $("#att_crse").val(resp.subjects[0].sub_crse);

      }

    }

    },

    error: function() {

      alert("An error occurred while fetching groups.");

    },

    cache: false

  });

}

// Bind the fetch_groups_by_period function to the period dropdown

$("#att_period").change(function() {

  fetch_groups_by_period();

});



function fillNextClass() {

  var usePath = $.trim($("#rootXPath").val());

  var formData = new FormData();

  var other_data = $('form#myforms').serializeArray();

  var mid = $.trim($("#markAttendanceId").val());



  // Collect attendance data for each student

  $('input[name^="attendance"]').each(function() {

    var studentCode = $(this).attr('name').match(/\[(.*?)\]/)[1];

    var isChecked = $(this).is(':checked') ? 'Y' : 'N';

    formData.append(`attendance[${studentCode}]`, isChecked);

  });

  formData.append("att_subject", $("#att_subject").val());

  formData.append("identity", "ATTENDANCE");

  formData.append("markAttendanceId", mid);

  formData.append("fill_next_class", 'true'); // Flag to indicate next class



  // Append other form data

  $.each(other_data, function(key, input) {

    formData.append(input.name, input.value);

  });



  $.ajax({

    url: usePath + "mark_attendance/ajax_process", // Updated to match the correct path for `create`

    type: 'POST',

    data: formData,

    contentType: false,

    processData: false,

    success: function(resp) {

      if (resp.status) {

        alert(resp.message); // Display success message

        //  window.location = usePath+"mark_attendance"

      } else {

        alert(resp.message); // Display error message

      }

    },

    error: function(xhr, status, error) {

      console.log("Error: ", error);

      alert("An error occurred while saving attendance.");

    }

  });

}

function close_profile_checkbox(){

  $("#sidebar-menu-toggle").hide();

}

function get_selected_item_val(){

  var selectedValues = [];

  var xvalues = [];

  var postype = []

  if( $("input[name='post_type_select[]']").is(":checked") ){

    $("input[name='post_type_select[]']:checked").each(function(){

      postype.push($(this).attr("id"));

      xvalues.push($(this).val() );

      selectedValues.push($(this).val());

    });

   // alert(selectedValues)

   

  }

  if( xvalues.length >0 ){

    xvalues  = xvalues.join(",")

    postypes = postype.join(",")

   // $("#prf_sewa_type").val(xvalues);

    $("#att_period").val(postypes);

  }else{

   // $("#prf_sewa_type").val('');

    $("#att_period").val('');

  }



  fetch_groups_by_period();

}

$(document).on("click","#att_period",function(){

  $("#sidebar-menu-toggle").toggle();

});

$(document).on('click', function(event) {  

  // Check if the click happened outside the ul

  if (!$(event.target).closest('ul').length && !$(event.target).is('input')) {

    // Close or hide the ul

      close_profile_checkbox();

    //$('ul').hide(); // Replace with your closing logic

  }

});



function under_maintainence(){

  alert("This Page is under modifications. Kindly wait for a while!");

}


  function process_delete_attendance() {
    var usePath = $.trim($("#rootXPath").val());
    var faculty = $.trim($("#att_fclty").val());
    var date    = $.trim($("#att_date").val());
    var period  = $.trim($("#att_period").val());
    var gruop   = $.trim($("#att_grp").val());

 if (!faculty ) {
   showToast("error","Please Select Faculty!");
   $("#att_fclty").focus();
   return false;
  }

   if (!date ) {
   showToast("error","Please Select Date!");
   $("#att_date").focus();
   return false;
  }

     if (!period ) {
   showToast("error","Please Select Period!");
   $("#att_period").focus();
   return false;
  }

     if (!gruop ) {
   showToast("error","Please Select Group!");
   $("#att_period").focus();
   return false;
  }

  var confirmMessage = `The attendance data is not recoverable. Are you sure you want to delete this attendance?`;
  if (!confirm(confirmMessage)) {
   $("#dhc_contract_date").focus();
    return false; 
  }
        $(".show_loader").removeClass("hidden");
        $(".no_loader").removeClass("hidden").addClass("hidden");
    $.ajax({
        url: usePath + "mark_attendance/ajax_process",
        type: 'POST',
        data: {'date': date, 'faculty': faculty,'period': period, 'gruop': gruop, 'identity': 'DELETEATTEND'},
        async: false,
        success: function (resp) {
                  $(".show_loader").removeClass("hidden").addClass("hidden");
        $(".no_loader").removeClass("hidden");
            if (resp.status) {
                alert(resp.message);
        window.location = usePath+"mark_attendance"

              } else {
                alert(resp.message);
        window.location = usePath+"mark_attendance"

            }
        },
        error: function () {
                  $(".show_loader").removeClass("hidden").addClass("hidden");
        $(".no_loader").removeClass("hidden");
        },
        cache: false
    });
}
