$(document).on("click","#cropImageBtn",function(){

  $("#myattachpropfile").val("Y");

});



$(document).ready(function(){
    flatpickr("#mmbr_join_date", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });

  $(document).ready(function(){
    flatpickr("#mmbr_dob", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });

  //  $(document).ready(function(){

  //   flatpickr("#mmbr_valid_upto", {

  //     dateFormat: "d-M-Y",

  //     allowInput: true,

  //     onOpen: function (selectedDates, dateStr, instance) {

  //       instance.setDate(instance.input.value, false);

  //     },

  //   });

  // });

  $(document).ready(function(){

    flatpickr("#mmbr_leave_date", {

      dateFormat: "d-M-Y",

      allowInput: true,

      onOpen: function (selectedDates, dateStr, instance) {

        instance.setDate(instance.input.value, false);

      },

    });

  });

function alertChecked(url){

    if( confirm("Are you sure want to delete ?")){

        window.location = url

    }

  }

function check_email_validation(email, id) {

  if (!ValidateEmail(email)) {

    showToast("info", "Invalid Email Address! Please type a valid email address.");

    $("#" + id).focus(); 

    return false; 

  }

  return true; 

}

function ValidateEmail(mail) {

  var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  return emailRegex.test(mail);

}

  function isNumberMyKeys(evt) {

    evt = (evt) ? evt : window.event;

    var charCode = (evt.which) ? evt.which : evt.keyCode;

    if (charCode > 31 && (charCode < 48 || charCode > 57)) {

        return false;

    }

    return true;

  }

  $(document).on("keypress","#member_list",function(e){

    var keycode = (e.keyCode ? e.keyCode : e.which );

      if( keycode == '13' ){

        filter_member_list();

      }

  

  });

  function filter_member_list(){

      var useroot = $("#rootXPath").val();

     

      $(".show_loader").removeClass("hidden");

      $(".no_loader").removeClass("hidden").addClass("hidden")

      $("form#myForms").submit(); 

  

  }


function set_global_focus(id){
  $("#"+id).focus();
}

function process_save_student_details(){
  var usePath           = $.trim( $("#rootXPath").val() );
  var formData          = new FormData();
  var other_data        = $('form#myforms').serializeArray();
  var mid               = $.trim( $("#mid").val() ); 
  var mmbr_code      = $.trim( $("#mmbr_code").val() );
  var mmbr_name    = $.trim( $("#mmbr_name").val() );
  var mmbr_gender       = $.trim( $("#mmbr_gender").val() ); 
  var mmbr_dob         = $.trim( $("#mmbr_dob").val() );
  var mmbr_contact      = $.trim( $("#mmbr_contact").val() );	
  var mmbr_email      = $.trim( $("#mmbr_email").val() );	

  if( mmbr_code == ''){
    showToast("info","Member Code is required.");
    setTimeout(function(){ set_global_focus('mmbr_code');},500);
    return false;
  }else if( mmbr_name == ''){
    showToast("info","Name is required.");
    setTimeout(function(){ set_global_focus('mmbr_name');},500);
    return false;
  }else if( mmbr_gender == ''){
    showToast("info","Gender is required.");
    setTimeout(function(){ set_global_focus('mmbr_gender');},500);
    return false;
  }else if( mmbr_contact == ''){
    showToast("info","Contact No. is required.");
    setTimeout(function(){ set_global_focus('mmbr_contact');},500);
    return false;
  }
  
      if (mmbr_contact) {
      if (mmbr_contact.length <= 9 || mmbr_contact.length > 10) {
        showToast("info","Mobile Number should be of 10 digits!");
          $("#mmbr_contact").focus();
          return false;
      }
    }
  
    if (mmbr_email!=''){
      if (!check_email_validation(mmbr_email, 'mmbr_email')) {
       setTimeout(function(){ set_global_focus('mmbr_email');},500);
       return false;
     }}
   
  formData.append("identity", "SAVEFACLTY");
  // Disable buttons + show spinner on Submit
var $submitBtn = $('button.btn-primary').first();
var originalText = $submitBtn.html();
$submitBtn.prop('disabled', true)
          .css({opacity: '0.7', cursor: 'not-allowed', 'pointer-events': 'none'})
          .html('<span class="member-spinner"></span> SAVING...');
$('button.btn-danger, a:has(button.btn-danger)').css({'pointer-events': 'none', opacity: '0.5'});

// helper to reset (in case of error)
function _resetSaveBtn(){
  $submitBtn.prop('disabled', false)
            .css({opacity: '', cursor: '', 'pointer-events': ''})
            .html(originalText);
  $('button.btn-danger, a:has(button.btn-danger)').css({'pointer-events': '', opacity: ''});
}

  formData.append("mid", mid);  
 
  $.each(other_data,function(key,input){
      formData.append(input.name,input.value);
  });
  
    setTimeout(function(){
  $.ajax({
          url: usePath+"member_list/ajax_process",
          type: 'POST',
          data: formData,
          async: false,
          contentType: false,
          processData: false,
          success: function (resp) {
            
            if( resp.status ){
              $("#mid").val(resp.profileid);
                                     
              showToast("success",resp.message);                  
               window.location.href = usePath + "member_list";
      
            }else{  
                                      
              showToast("error",resp.message); 
              _resetSaveBtn();
            }

          },
          error: function () {
              showToast("error","An error occurred while saving. Please try again.");
              $(".process_save").show();
              _resetSaveBtn();
          },
          cache: false
           });

    },500);
}


function enrollFinger(memberId, memberName) {
  $("#enroll-status").html('<span class="text-info">⏳ Sending command to device...</span>');
  
  $.ajax({
    url: 'http://localhost:5000/enroll',
    type: 'POST',
    contentType: 'application/json',
    data: JSON.stringify({
      member_id: memberId,
      member_name: memberName,
      compcode: 'SF'
    }),
    success: function(resp) {
      if (resp.status) {
        $("#enroll-status").html(
          '<span class="text-success">✓ ' + resp.message + '</span>'
        );
        // Reload after 3 seconds to show new mapping
        setTimeout(function(){ location.reload(); }, 3000);
      } else {
        $("#enroll-status").html(
          '<span class="text-danger">Error: ' + resp.message + '</span>'
        );
      }
    },
    error: function() {
      $("#enroll-status").html(
        '<span class="text-danger">⚠ Could not reach enrollment service. Is the gym laptop running?</span>'
      );
    }
  });
}

function saveManualMapping(memberId, memberName) {
  var deviceUserId = $.trim($("#manual_device_uid").val());
  if (!deviceUserId) {
    showToast("info", "Please enter Device User ID");
    return;
  }

  var usePath = $.trim($("#rootXPath").val());
  var formData = new FormData();
  formData.append("member_id", memberId);
  formData.append("device_user_id", deviceUserId);
  formData.append("member_name", memberName);

  $.ajax({
    url: usePath + "member_list/save_manual_mapping",
    type: 'POST',
    data: formData,
    contentType: false,
    processData: false,
    success: function(resp) {
      if (resp.status) {
        showToast("success", "Mapping saved successfully!");
        setTimeout(function(){ location.reload(); }, 1000);
      } else {
        showToast("error", resp.message);
      }
    },
    error: function() {
      showToast("error", "Failed to save mapping");
    }
  });
}

function removeMapping(mappingId) {
  if (!confirm("Remove this fingerprint mapping? Member won't be able to use biometric until re-enrolled.")) return;
  
  var usePath = $.trim($("#rootXPath").val());
  var formData = new FormData();
  formData.append("mapping_id", mappingId);

  $.ajax({
    url: usePath + "member_list/remove_mapping",
    type: 'POST',
    data: formData,
    contentType: false,
    processData: false,
    success: function(resp) {
      if (resp.status) {
        showToast("success", "Mapping removed");
        setTimeout(function(){ location.reload(); }, 1000);
      } else {
        showToast("error", resp.message);
      }
    }
  });
}