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
      $("#member-table-loader").addClass("active");
      $(".show_loader").removeClass("hidden");
      $(".no_loader").removeClass("hidden").addClass("hidden");
      $("form#myForms").attr("action", useroot + "member_list/search");
      $("form#myForms").submit(); 
  }

function set_global_focus(id){
  $("#"+id).focus();
}
function process_save_student_details(){
  var usePath      = $.trim($("#rootXPath").val());
  var formData     = new FormData();
  var other_data   = $('form#myforms').serializeArray();
  var mid          = $.trim($("#mid").val());
  var mmbr_code    = $.trim($("#mmbr_code").val());
  var mmbr_name    = $.trim($("#mmbr_name").val());
  var mmbr_gender  = $.trim($("#mmbr_gender").val());
  var mmbr_contact = $.trim($("#mmbr_contact").val());
  var mmbr_email   = $.trim($("#mmbr_email").val());

  // Remove any previous error banner
  $("#form-error-banner").remove();

  if (mmbr_code == '') {
    showFormError("Member Code is required.");
    set_global_focus('mmbr_code');
    return false;
  } else if (mmbr_name == '') {
    showFormError("Name is required. Fill it in and click Submit again.");
    set_global_focus('mmbr_name');
    return false;
  } else if (mmbr_gender == '') {
    showFormError("Gender is required. Fill it in and click Submit again.");
    set_global_focus('mmbr_gender');
    return false;
  } else if (mmbr_contact == '') {
    showFormError("Contact No. is required. Fill it in and click Submit again.");
    set_global_focus('mmbr_contact');
    return false;
  }

  if (mmbr_contact.length < 10 || mmbr_contact.length > 10) {
    showFormError("Mobile Number must be exactly 10 digits. Please correct it and click Submit again.");
    $("#mmbr_contact").focus();
    return false;
  }

  if (mmbr_email != '') {
    if (!check_email_validation(mmbr_email, 'mmbr_email')) {
      showFormError("Please enter a valid Email address.  Correct it and click Submit again.");
      set_global_focus('mmbr_email');
      return false;
    }
  }

  formData.append("identity", "SAVEFACLTY");
  formData.append("mid", mid);
  $.each(other_data, function(key, input){
    formData.append(input.name, input.value);
  });

  var $submitBtn  = $('button.btn-primary').first();
  var originalText = $submitBtn.html();
  $submitBtn.prop('disabled', true)
    .css({opacity:'0.7', cursor:'not-allowed', 'pointer-events':'none'})
    .html('<span class="member-spinner"></span> SAVING...');
  $('button.btn-danger, a:has(button.btn-danger)')
    .css({'pointer-events':'none', opacity:'0.5'});

  function _resetSaveBtn(){
    $submitBtn.prop('disabled', false)
      .css({opacity:'', cursor:'', 'pointer-events':''})
      .html(originalText);
    $('button.btn-danger, a:has(button.btn-danger)')
      .css({'pointer-events':'', opacity:''});
  }

  setTimeout(function(){
    $.ajax({
      url: usePath + "member_list/ajax_process",
      type: 'POST',
      data: formData,
      async: false,
      contentType: false,
      processData: false,
      success: function(resp) {
        if (resp.status) {
          $("#mid").val(resp.profileid);
          showToast("success", resp.message);
          window.location.href = usePath + "member_list";
        } else {
          // Server error — show inline banner, never toaster
          showFormError(resp.message);
          _resetSaveBtn();
        }
      },
      error: function() {
        showFormError("An error occurred while saving. Please try again.");
        _resetSaveBtn();
      },
      cache: false
    });
  }, 500);
}

function enrollFinger(memberId, memberName) {
    var btn = event.target;
    btn.disabled = true;
    btn.innerText = 'Enrolling...';
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
                setTimeout(function(){ location.reload(); }, 3000);
            } else {
                // ← Re-enable on failure so staff can try again
                btn.disabled = false;
                btn.innerText = '👆 Enroll Fingerprint';
                $("#enroll-status").html(
                    '<span class="text-danger">Error: ' + resp.message + '</span>'
                );
            }
        },
        error: function() {
            // ← Re-enable on network error so staff can try again
            btn.disabled = false;
            btn.innerText = '👆 Enroll Fingerprint';
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

$(document).ready(function() {
  // Auto capitalize first letter of each word as user types
  $(document).on("input", "#mmbr_name", function() {
    var pos = this.selectionStart; // remember cursor position
    var val = $(this).val();
    var capitalized = val.replace(/\b\w/g, function(char) {
      return char.toUpperCase();
    });
    $(this).val(capitalized);
    this.setSelectionRange(pos, pos); // restore cursor position
  });
});

$(document).ready(function () {
  if (!$("#members_table").length) return;
  var rootPath = $("#rootXPath").val();

  $("#members_table").DataTable({
    processing: true,
    serverSide: true,
    searchDelay: 350,
    order: [[2, "asc"]],            // default sort: Member Name
    ajax: {
      url: rootPath + "member_list/datatable",
      type: "POST"
    },
    columnDefs: [
      { targets: 0, width: 10, orderable: false },  // S.No
      { targets: 9, orderable: false }              // Action
    ]
  });
});

/* ---- Collect Payment modal (member profile) ---- */
function openCollectPayment(){
  document.getElementById('collectPaymentModal').style.display = 'block';
}
function closeCollectPayment(){
  document.getElementById('collectPaymentModal').style.display = 'none';
}
function submitCollectPayment(){
  var usePath = $.trim($("#rootXPath").val());
  var amount  = $.trim($("#cp_amount").val());
  if (amount === "" || parseFloat(amount) <= 0){ alert("Enter a valid amount."); return; }

  var $btn = $("#cp_save_btn");
  $btn.prop("disabled", true).text("Saving...");

  $.ajax({
    url: usePath + "member_subscriptions/ajax_process",
    type: "POST",
    dataType: "json",
    data: {
      identity: "COLLECTPAY",
      subscription_id: $("#cp_subscription_id").val(),
      pay_amount: amount,
      pay_mode: $("#cp_mode").val(),
      pay_date: $.trim($("#cp_date").val()),
      pay_remarks: $.trim($("#cp_remarks").val())
    },
    success: function(resp){
      if (resp.status){ location.reload(); }
      else { alert(resp.message); $btn.prop("disabled", false).text("Save Payment"); }
    },
    error: function(){ alert("Error saving payment. Please try again."); $btn.prop("disabled", false).text("Save Payment"); }
  });
}

/* ---- Extend / Freeze modal (member profile) ---- */
function openExtendModal(){
  var btn = document.getElementById('ext_save_btn');
  btn.disabled = false; btn.textContent = "Save";
  document.getElementById('extendModal').style.display = 'block';
}
function closeExtendModal(){
  document.getElementById('extendModal').style.display = 'none';
}
function submitExtend(){
  var usePath = $.trim($("#rootXPath").val());
  var days    = $.trim($("#ext_days").val());
  if (days === "" || parseInt(days, 10) <= 0){ alert("Enter a valid number of days."); return; }

  var $btn = $("#ext_save_btn");
  $btn.prop("disabled", true).text("Saving...");

  $.ajax({
    url: usePath + "member_subscriptions/ajax_process",
    type: "POST",
    dataType: "json",
    data: {
      identity: "EXTENDSUB",
      subscription_id: $("#ext_subscription_id").val(),
      extend_days: days,
      extend_reason: $.trim($("#ext_reason").val())
    },
    success: function(resp){
      if (resp.status){ location.reload(); }
      else { alert(resp.message); $btn.prop("disabled", false).text("Save"); }
    },
    error: function(){ alert("Error extending membership. Please try again."); $btn.prop("disabled", false).text("Save"); }
  });
}
