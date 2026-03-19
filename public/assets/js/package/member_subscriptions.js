

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

  $(document).on("keypress","#member_subscriptions",function(e){
    var keycode = (e.keyCode ? e.keyCode : e.which );
      if( keycode == '13' ){
        filter_member_subscriptions();
      }
  });

  function filter_member_subscriptions(){
      var useroot = $("#rootXPath").val();
      $(".show_loader").removeClass("hidden");
      $(".no_loader").removeClass("hidden").addClass("hidden");
      $("form#myForms").attr("action",useroot+"member_subscriptions/search");
      $("form#myForms").submit(); 
  }


function set_global_focus(id){
  $("#"+id).focus();
}

function save_member_subscription(){
  var usePath           = $.trim( $("#rootXPath").val() );
  var formData          = new FormData();
  var other_data        = $('form#myforms').serializeArray();
  var mid               = $.trim( $("#mid").val() ); 
  var ms_sbscrptn_no      = $.trim( $("#ms_sbscrptn_no").val() );
  var ms_member_id    = $.trim( $("#ms_member_id").val() );
  var ms_plan_id       = $.trim( $("#ms_plan_id").val() ); 
  var ms_start_date         = $.trim( $("#ms_start_date").val() );
  var ms_amount_paid      = $.trim( $("#ms_amount_paid").val() );	
  var ms_payment_mode      = $.trim( $("#ms_payment_mode").val() );	

  if( ms_sbscrptn_no == ''){
    showToast("info","Subscription No. is required.");
    setTimeout(function(){ set_global_focus('ms_sbscrptn_no');},500);
    return false;
  }else if( ms_member_id == ''){
    showToast("info","Member is required.");
    setTimeout(function(){ set_global_focus('ms_member_id');},500);
    return false;
  }else if( ms_plan_id == ''){
    showToast("info","Plan is required.");
    setTimeout(function(){ set_global_focus('ms_plan_id');},500);
    return false;
  }else if( ms_start_date == ''){
    showToast("info","Start Date is required.");
    setTimeout(function(){ set_global_focus('ms_start_date');},500);
    return false;
  }else if( ms_amount_paid == ''){
    showToast("info","Amount is required.");
    setTimeout(function(){ set_global_focus('ms_amount_paid');},500);
    return false;
  }
var isOpen = $("#open_plan_row").is(":visible");

if(isOpen){

  var open_amount = $("#ms_open_amount").val();
  var open_end = $("#ms_open_end_date").val();

  if(open_amount == ""){
    showToast("info","Custom amount required");
    return false;
  }

  if(open_end == ""){
    showToast("info","Custom end date required");
    return false;
  }
}
  formData.append("identity", "SAVESUBSCR");
  formData.append("mid", mid);  
 
  $.each(other_data,function(key,input){
      formData.append(input.name,input.value);
  });
  
   $(".no_loader").removeClass("hidden").addClass("hidden");
   $(".loader").removeClass("hidden");
    setTimeout(function(){
  $.ajax({
          url: usePath+"member_subscriptions/ajax_process",
          type: 'POST',
          data: formData,
          async: false,
          contentType: false,
          processData: false,
          success: function (resp) {
            
            if( resp.status ){
              $("#mid").val(resp.profileid);
              $(".no_loader").removeClass("hidden");
               $(".loader").removeClass("hidden").addClass("hidden");                          
              showToast("success",resp.message);                  
               window.location.href = usePath + "member_subscriptions";
      
            }else{  
              $(".no_loader").removeClass("hidden");
               $(".loader").removeClass("hidden").addClass("hidden");                         
              showToast("error",resp.message); 
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
