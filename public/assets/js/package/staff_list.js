$(document).on("click","#cropImageBtn",function(){

  $("#myattachpropfile").val("Y");

});



$(document).ready(function(){
    flatpickr("#stf_join_date", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });

  $(document).ready(function(){
    flatpickr("#stf_dob", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });

  //  $(document).ready(function(){

  //   flatpickr("#stf_valid_upto", {

  //     dateFormat: "d-M-Y",

  //     allowInput: true,

  //     onOpen: function (selectedDates, dateStr, instance) {

  //       instance.setDate(instance.input.value, false);

  //     },

  //   });

  // });

  $(document).ready(function(){

    flatpickr("#stf_leave_date", {

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
  var stf_code      = $.trim( $("#stf_code").val() );
  var stf_name    = $.trim( $("#stf_name").val() );
  var stf_gender       = $.trim( $("#stf_gender").val() ); 
  var stf_dob         = $.trim( $("#stf_dob").val() );
  var stf_contact      = $.trim( $("#stf_contact").val() );	
  var stf_email      = $.trim( $("#stf_email").val() );	

  if( stf_code == ''){
    showToast("info","Member Code is required.");
    setTimeout(function(){ set_global_focus('stf_code');},500);
    return false;
  }else if( stf_name == ''){
    showToast("info","Name is required.");
    setTimeout(function(){ set_global_focus('stf_name');},500);
    return false;
  }else if( stf_gender == ''){
    showToast("info","Gender is required.");
    setTimeout(function(){ set_global_focus('stf_gender');},500);
    return false;
  }else if( stf_contact == ''){
    showToast("info","Contact No. is required.");
    setTimeout(function(){ set_global_focus('stf_contact');},500);
    return false;
  }
  
      if (stf_contact) {
      if (stf_contact.length <= 9 || stf_contact.length > 10) {
        showToast("info","Mobile Number should be of 10 digits!");
          $("#stf_contact").focus();
          return false;
      }
    }
  
    if (stf_email!=''){
      if (!check_email_validation(stf_email, 'stf_email')) {
       setTimeout(function(){ set_global_focus('stf_email');},500);
       return false;
     }}
   
  formData.append("identity", "STAFF");
  formData.append("mid", mid);  
 
  $.each(other_data,function(key,input){
      formData.append(input.name,input.value);
  });
  
   $(".no_loader").removeClass("hidden").addClass("hidden");
   $(".loader").removeClass("hidden");
    setTimeout(function(){
  $.ajax({
          url: usePath+"staff_list/ajax_process",
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
               window.location.href = usePath + "staff_list";
      
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


