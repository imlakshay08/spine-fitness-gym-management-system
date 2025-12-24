$(document).on("click","#cropImageBtn",function(){

  $("#myattachpropfile").val("Y");

});



$(document).ready(function(){
    flatpickr("#trn_join_date", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });

  $(document).ready(function(){
    flatpickr("#trn_dob", {
      dateFormat: "d-M-Y",
      allowInput: true,
      onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(instance.input.value, false);
      },
    });
  });

  //  $(document).ready(function(){

  //   flatpickr("#trn_valid_upto", {

  //     dateFormat: "d-M-Y",

  //     allowInput: true,

  //     onOpen: function (selectedDates, dateStr, instance) {

  //       instance.setDate(instance.input.value, false);

  //     },

  //   });

  // });

  $(document).ready(function(){

    flatpickr("#trn_leave_date", {

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

  $(document).on("keypress","#trainer_list",function(e){

    var keycode = (e.keyCode ? e.keyCode : e.which );

      if( keycode == '13' ){

        filter_trainer_list();

      }

  

  });

  function filter_trainer_list(){

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
  var trn_code      = $.trim( $("#trn_code").val() );
  var trn_name    = $.trim( $("#trn_name").val() );
  var trn_gender       = $.trim( $("#trn_gender").val() ); 
  var trn_dob         = $.trim( $("#trn_dob").val() );
  var trn_contact      = $.trim( $("#trn_contact").val() );	
  var trn_email      = $.trim( $("#trn_email").val() );	

  if( trn_code == ''){
    showToast("info","Trainer Code is required.");
    setTimeout(function(){ set_global_focus('trn_code');},500);
    return false;
  }else if( trn_name == ''){
    showToast("info","Name is required.");
    setTimeout(function(){ set_global_focus('trn_name');},500);
    return false;
  }else if( trn_gender == ''){
    showToast("info","Gender is required.");
    setTimeout(function(){ set_global_focus('trn_gender');},500);
    return false;
  }else if( trn_contact == ''){
    showToast("info","Contact No. is required.");
    setTimeout(function(){ set_global_focus('trn_contact');},500);
    return false;
  }
  
      if (trn_contact) {
      if (trn_contact.length <= 9 || trn_contact.length > 10) {
        showToast("info","Mobile Number should be of 10 digits!");
          $("#trn_contact").focus();
          return false;
      }
    }
  
    if (trn_email!=''){
      if (!check_email_validation(trn_email, 'trn_email')) {
       setTimeout(function(){ set_global_focus('trn_email');},500);
       return false;
     }}
   
  formData.append("identity", "TRAINER");
  formData.append("mid", mid);  
 
  $.each(other_data,function(key,input){
      formData.append(input.name,input.value);
  });
  
   $(".no_loader").removeClass("hidden").addClass("hidden");
   $(".loader").removeClass("hidden");
    setTimeout(function(){
  $.ajax({
          url: usePath+"trainer_list/ajax_process",
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
               window.location.href = usePath + "trainer_list";
      
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


