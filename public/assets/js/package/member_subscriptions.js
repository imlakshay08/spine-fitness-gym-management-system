

$(document).ready(function(){
    flatpickr("#ms_start_date", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });

  $(document).ready(function(){
    flatpickr("#ms_end_date", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });

    $(document).ready(function(){
    flatpickr("#ms_open_end_date", {
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

$(document).on("keypress", "#member_search", function(e) {
  var keycode = (e.keyCode ? e.keyCode : e.which);
  if (keycode == '13') {
    filter_member_subscriptions();
  }
});
  function filter_member_subscriptions(){
      var useroot = $("#rootXPath").val();
      $("#subscription-table-loader").addClass("active");
      $(".show_loader").removeClass("hidden");
      $(".no_loader").removeClass("hidden").addClass("hidden");
      $("form#myForms").attr("action",useroot+"member_subscriptions/search");
      $("form#myForms").submit(); 
  }

function set_global_focus(id){
  $("#"+id).focus();
}
function save_member_subscription(){
  var usePath        = $.trim($("#rootXPath").val());
  var formData       = new FormData();
  var other_data     = $('form#myforms').serializeArray();
  var mid            = $.trim($("#mid").val());
  var ms_sbscrptn_no = $.trim($("#ms_sbscrptn_no").val());
  var ms_member_id   = $.trim($("#ms_member_id").val());
  var ms_plan_id     = $.trim($("#ms_plan_id").val());
  var ms_start_date  = $.trim($("#ms_start_date").val());
  var ms_amount_paid = $.trim($("#ms_amount_paid").val());

  // Remove any previous error banner
  $("#form-error-banner").remove();

  if (ms_sbscrptn_no == '') {
    showFormError("Subscription No. is required.");
    set_global_focus('ms_sbscrptn_no');
    return false;
  } else if (ms_member_id == '') {
    showFormError("Please select a Member. Choose one from the dropdown and click Submit again.");
    set_global_focus('ms_member_id');
    return false;
  } else if (ms_plan_id == '') {
    showFormError("Please select a Plan. Choose one from the dropdown and click Submit again.");
    set_global_focus('ms_plan_id');
    return false;
  } else if (ms_start_date == '') {
    showFormError("Start Date is required. Select a date and click Submit again.");
    set_global_focus('ms_start_date');
    return false;
  } else if (ms_amount_paid == '') {
    showFormError("Amount Paid is required. Fill it in and click Submit again.");
    set_global_focus('ms_amount_paid');
    return false;
  }

  var isOpen = $("#open_plan_row").is(":visible");
  if (isOpen) {
    if ($.trim($("#ms_open_amount").val()) == "") {
      showFormError("Custom amount is required for Open plan. Fill it in and click Submit again.");
      set_global_focus('ms_open_amount');
      return false;
    }
    if ($.trim($("#ms_open_end_date").val()) == "") {
      showFormError("Custom end date is required for Open plan. Select a date and click Submit again.");
      set_global_focus('ms_open_end_date');
      return false;
    }
  }

  formData.append("identity", "SAVESUBSCR");
  formData.append("mid", mid);
  $.each(other_data, function(key, input){
    formData.append(input.name, input.value);
  });

  var $submitBtn   = $('button.btn-primary').first();
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
      url: usePath + "member_subscriptions/ajax_process",
      type: 'POST',
      data: formData,
      async: false,
      contentType: false,
      processData: false,
      success: function(resp) {
        if (resp.status) {
          $("#mid").val(resp.profileid);
          showToast("success", resp.message);
          window.location.href = usePath + "member_subscriptions";
        } else {
          // Server errors like active subscription conflict — inline banner
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

function fill_end_date() {

    var usePath   = $.trim($("#rootXPath").val());
    var plan_id   = $("#ms_plan_id").val();
    var startDate = $("#ms_start_date").val();

    if (plan_id == "") {
        $("#ms_end_date").val("");
        return;
    }

    $.ajax({
        url: usePath + "member_subscriptions/ajax_process",
        type: "POST",
        dataType: "json",
        data: {
            identity: "FILLENDDATE",
            ms_plan_id: plan_id,
            ms_start_date: startDate
        },
        success: function (resp) {

            if (resp.status === true) {

                if (resp.is_open === true) {

                    // OPEN PLAN
                    $("#open_plan_row").show();

                    $("#ms_end_date").prop("readonly", false);
                    $("#ms_end_date").val("");

                } else {

                    // NORMAL PLAN
                    $("#open_plan_row").hide();

                    $("#ms_open_amount").val("");
                    $("#ms_open_end_date").val("");

                    $("#ms_end_date").prop("readonly", true);
                    $("#ms_end_date").val(resp.end_date);

                }

            } else {
                $("#ms_end_date").val("");
            }

        }
    });
}
  
$(document).ready(function() {
  $('#ms_member_id').select2({
    placeholder: "-Select-",
    allowClear: true,
    width: 'resolve'  // auto width
  });
  
   $('#ms_member_id').on('select2:open', function () {
    $('.select2-search__field').focus();
  });
  
});
