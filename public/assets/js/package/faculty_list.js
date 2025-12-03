$(document).on("click","#cropImageBtn",function(){

  $("#myattachpropfile").val("Y");

});



$(document).ready(function(){

    flatpickr("#fclty_join_date", {

      dateFormat: "d-M-Y",

      allowInput: true,

      onOpen: function (selectedDates, dateStr, instance) {

        instance.setDate(instance.input.value, false);

      },

    });

  });

  $(document).ready(function(){

    flatpickr("#fclty_dob", {

      dateFormat: "d-M-Y",

      allowInput: true,

      onOpen: function (selectedDates, dateStr, instance) {

        instance.setDate(instance.input.value, false);

      },

    });

  });

  //  $(document).ready(function(){

  //   flatpickr("#fclty_valid_upto", {

  //     dateFormat: "d-M-Y",

  //     allowInput: true,

  //     onOpen: function (selectedDates, dateStr, instance) {

  //       instance.setDate(instance.input.value, false);

  //     },

  //   });

  // });

  $(document).ready(function(){

    flatpickr("#fclty_leave_date", {

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

  function check_email_validation(email,id){

    if (!ValidateEmail(email )) {

         alert("Invalid email address.");

         $("#"+id).val('');

         $("#"+id).focus();

     }else {

         

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

        filter_faculty_list();

      }

  

  });

  function filter_faculty_list(){

      var useroot = $("#rootXPath").val();

     

      $(".show_loader").removeClass("hidden");

      $(".no_loader").removeClass("hidden").addClass("hidden")

      $("form#myForms").submit(); 

  

  }



  function faculty_img_saving() {

    var usePath    = $("#rootXPath").val();

    var formData   = new FormData();

    var other_data = $('form#myForms').serializeArray();

    var img        = $('#item-img-output').attr('src'); 

    var facultyId  = $("#mid").val();

    var fcultyimgId   = $("#facultyimgeId").val();



    $("#productServer").val('Y');// Get the current image src

   

     if (img && img.startsWith("data:")) {

        formData.append("fclty_img", img);

     }else{

       formData.append("facultyimgeId", '');  

     }

     formData.append("fclty_code", facultyId);

     formData.append("facultyimgeId", fcultyimgId);

     formData.append("is_process", fcultyimgId ? 'update' : 'create');

     formData.append("productServer", 'Y');  

      $.each(other_data,function(key,input){

        formData.append(input.name,input.value);

    });

    $.ajax({

        url: usePath + "faculty_list/ajax_process",

        type: 'POST',

        data: formData,

        async: false,

        contentType: false,

        processData: false,

        success: function (resp) {

            // Ensure resp.message is defined before using it

            

            if (resp.status) {

                // Refresh the page or reload the table data

                location.reload();

            } 

        }

      

    });

}



var $uploadCrop, rawImg;

function readFile(input) {
  if (input.files && input.files[0]) {
    var reader = new FileReader();
    reader.onload = function (e) {
      $('.upload-demo').addClass('ready');
      $('#cropImagePop').modal('show');
      rawImg = e.target.result;
    }
    reader.readAsDataURL(input.files[0]);
  } else {
    alert("Sorry - your browser doesn't support the FileReader API");
  }
}

$uploadCrop = $('#upload-demo').croppie({
  viewport: {
    width: 300,
    height: 300
  },
  enforceBoundary: false,
  enableExif: true
});

$('#cropImagePop').on('shown.bs.modal', function() {
  $uploadCrop.croppie('bind', {
    url: rawImg
  }).then(function() {
    console.log('jQuery bind complete');
  });
});

$('.item-img').on('change', function () {
  readFile(this);
});

$('#cropImageBtn').on('click', function () {
  $uploadCrop.croppie('result', {
    type: 'base64',
    format: 'png',
    size: {width: 300, height: 300}
  }).then(function (resp) {
    $('#item-img-output').attr('src', resp);
    $("#new_fac_img").val(resp);
    $('#cropImagePop').modal('hide');
    $('.example-image-link').attr('href', resp);    // Update the href in the anchor tag
  });
});



function faculty_age_calculate(){

  var usePath     = $.trim( $("#rootXPath").val() );

  var birthdate   = $.trim( $("#fclty_dob").val() );



  $.ajax({

                  url: usePath+"faculty_list/ajax_process",

                  type: 'POST',

                  data: {'birthdate': birthdate,'identity':'BIRTHCALC'},

                  async: false,

                  success: function (resp) {

                      if ( resp.status ){

                          var sdata = resp.data;

                          var sages = resp.ages.split(" ")

                          

                          if( parseInt(sages[0]) <18 || sages[0] == ''){

                                 alert("Age should be greater than or equal to 18 years");

                                 $("#fclty_dob").val('');

                                 $(".age_calcualted").html('');

                                 $("#fclty_dob").focus();

                                 return false;

                          }else{

                                  $("#so_superannuationdate").val(sdata);

                                  $(".age_calcualted").html(resp.ages);

                                  $("#mytotal_sewleft").html(resp.leftsewa);

                          }

                      }else{

                           $("#so_superannuationdate").val('');

                           $(".age_calcualted").html('');

                           $("#mytotal_sewleft").html('');

                      }





                  },

                  error: function () {

                         $("#so_superannuationdate").val('');

                          $(".age_calcualted").html('');

                           $("#mytotal_sewleft").html('');

                  },

                  cache: false

      });

}


function set_global_focus(id){
  $("#"+id).focus();
}

function process_save_student_details(){
  var usePath           = $.trim( $("#rootXPath").val() );
  var formData          = new FormData();
  var other_data        = $('form#myforms').serializeArray();
  var mid               = $.trim( $("#mid").val() ); 
  var fclty_code      = $.trim( $("#fclty_code").val() );
  var fclty_name    = $.trim( $("#fclty_name").val() );
  var fclty_gender       = $.trim( $("#fclty_gender").val() ); 
  var fclty_dob         = $.trim( $("#fclty_dob").val() );
  var fclty_contact      = $.trim( $("#fclty_contact").val() );
    var image         = $('#fclty_img').get(0).files[0];
  var signature         = $('#fclty_signature').get(0).files[0];
 // var stdnt_dtl_email      = $.trim( $("#stdnt_dtl_email").val() );	

  if( fclty_code == ''){
    showToast("error","Faculty Code is required.");
    setTimeout(function(){ set_global_focus('fclty_code');},500);
    return false;
  }else if( fclty_name == ''){
    showToast("error","Name is required.");
    setTimeout(function(){ set_global_focus('fclty_name');},500);
    return false;
  }else if( fclty_gender == ''){
    showToast("error","Gender is required.");
    setTimeout(function(){ set_global_focus('fclty_gender');},500);
    return false;
  }else if( fclty_dob == ''){
    showToast("error","Date of Birth is required.");
    setTimeout(function(){ set_global_focus('fclty_dob');},500);
    return false;
  }else if( fclty_contact == ''){
    showToast("error","Contact No. is required.");
    setTimeout(function(){ set_global_focus('fclty_contact');},500);
    return false;
  }
  
   
  formData.append("identity", "SAVEFACLTY");
  formData.append("mid", mid);  
  if( typeof(signature) != "undefined" ){
    formData.append("fclty_signature", signature); 
  }else{
  formData.append("fclty_signature", '');
  }
  if( typeof(signature) != "undefined" ){
    formData.append("fclty_img", image); 
  }else{
  formData.append("fclty_img", '');
  } 
 
  $.each(other_data,function(key,input){
      formData.append(input.name,input.value);
  });
  
   $(".no_loader").removeClass("hidden").addClass("hidden");
   $(".loader").removeClass("hidden");
    setTimeout(function(){
  $.ajax({
          url: usePath+"faculty_list/ajax_process",
          type: 'POST',
          data: formData,
          async: false,
          contentType: false,
          processData: false,
          success: function (resp) {
            
            if( resp.status ){
              $("#mid").val(resp.profileid);
              $("#facultyimgeId").val(resp.profileimage);
              $("#cursignature").val(resp.signimages);
              $(".no_loader").removeClass("hidden");
               $(".loader").removeClass("hidden").addClass("hidden");                          
              showToast("success",resp.message);                  
               window.location.href = usePath + "faculty_list";
      
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


